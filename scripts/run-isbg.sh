#!/usr/bin/env bash
# run-isbg.sh – Verarbeitet alle konfigurierten Mailboxen mit isbg + SpamAssassin.
# Wird vom Entrypoint-Loop aufgerufen (Intervall: IMAP_CHECK_INTERVAL Sekunden).
#
# Konfiguration pro Mailbox: /etc/isgb/mailboxes/<name>.conf
# Relevante Schlüssel:
#   [connection]  host, port, username, auth_secret, use_ssl
#   [actions]     move_to_folder|spaminbox, ham_folder, spam_learn_folder

set -uo pipefail

CONFIG_DIR="${CONFIG_DIR:-/etc/isgb/mailboxes}"
LOG_DIR="${LOG_DIR:-/var/log/isgb}"
LOG_FILE="${LOG_DIR}/isbg.log"

mkdir -p "${LOG_DIR}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ISBG] $*" | tee -a "${LOG_FILE}"
}

# Liest einen Wert aus einer INI-Konfigurationsdatei (alle Sektionen).
ini_get() {
    local file="$1" key="$2"
    grep -E "^\s*${key}\s*=" "${file}" 2>/dev/null \
        | head -1 \
        | sed 's/^[^=]*=\s*//' \
        | sed 's/[[:space:]]*#.*//' \
        | tr -d '\r' \
        | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# isbg-Version beim Start loggen (hilft bei Diagnose)
ISBG_VERSION=$(isbg --version 2>&1 || echo "unbekannt")
log "=== Starte Mailbox-Spam-Check (isbg: ${ISBG_VERSION}) ==="

processed=0
errors=0

for conf in "${CONFIG_DIR}"/*.conf; do
    [ -f "$conf" ] || continue
    name=$(basename "$conf" .conf)

    # Deaktivierte Mailboxen überspringen
    enabled=$(ini_get "$conf" "enabled")
    [ "$enabled" = "false" ] && { log "Überspringe ${name} (deaktiviert)"; continue; }

    host=$(ini_get "$conf" "host")
    port=$(ini_get "$conf" "port")
    username=$(ini_get "$conf" "username")
    password=$(ini_get "$conf" "auth_secret")
    use_ssl=$(ini_get "$conf" "use_ssl")
    spam_folder=$(ini_get "$conf" "spaminbox")
    [ -z "$spam_folder" ] && spam_folder=$(ini_get "$conf" "move_to_folder")
    ham_folder=$(ini_get "$conf" "ham_folder")
    spam_learn_folder=$(ini_get "$conf" "spam_learn_folder")

    # Beispiel-Config oder fehlende Pflichtfelder überspringen
    if [ -z "$host" ] || [ -z "$username" ] || [ -z "$password" ] \
        || [ "$host" = "mail.example.com" ] \
        || [ "$password" = "[REPLACE_WITH_YOUR_APP_PASSWORD]" ]; then
        log "Überspringe ${name}: Beispiel-Config oder fehlende Zugangsdaten"
        continue
    fi

    log "Verarbeite: ${name} (${username}@${host})"

    ISBG_ARGS=(
        "--imaphost"    "$host"
        "--imapport"    "${port:-993}"
        "--imapuser"    "$username"
        "--imappasswd"  "$password"
        "--spaminbox"   "${spam_folder:-INBOX.Spam}"
        "--maxsize"     "400000"
    )

    [ "${use_ssl:-true}" = "false" ] && ISBG_ARGS+=("--nossl")

    if [ -n "$ham_folder" ]; then
        # Mails in ham_folder als Ham lernen (False-Positive-Korrektur)
        ISBG_ARGS+=("--learnhambox" "$ham_folder")
        log "  Ham-Lernordner: ${ham_folder}"
    fi

    if [ -n "$spam_learn_folder" ]; then
        ISBG_ARGS+=("--learnspambox" "$spam_learn_folder")
        log "  Spam-Lernordner: ${spam_learn_folder}"
    fi

    # Exaktes Kommando loggen (Passwort ausgeblendet) für einfachere Fehleranalyse
    log_args=("${ISBG_ARGS[@]//${password}/***}")
    log "  Kommando: isbg ${log_args[*]}"

    box_log="${LOG_DIR}/${name}.log"
    if isbg "${ISBG_ARGS[@]}" >> "${box_log}" 2>&1; then
        log "OK: ${name}"
        processed=$((processed + 1))
    else
        exit_code=$?
        log "FEHLER: ${name} (Exit-Code: ${exit_code}) – Details: ${box_log}"
        errors=$((errors + 1))
    fi
done

log "=== Check abgeschlossen: ${processed} verarbeitet, ${errors} Fehler ==="
