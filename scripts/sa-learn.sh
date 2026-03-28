#!/bin/bash
# SpamAssassin Lernlauf für isGB
# Wird beim Containerstart und täglich um 02:00 Uhr via Cron ausgeführt.
#
# Lerndaten ablegen in:
#   Spam: /var/lib/isgb/spam/  (mbox-Dateien oder Maildir-Verzeichnisse)
#   Ham:  /var/lib/isgb/ham/   (mbox-Dateien oder Maildir-Verzeichnisse)
# Pfade können über Umgebungsvariablen SA_SPAM_DIR / SA_HAM_DIR überschrieben werden.

SPAM_DIR="${SA_SPAM_DIR:-/var/lib/isgb/spam}"
HAM_DIR="${SA_HAM_DIR:-/var/lib/isgb/ham}"
LOG_DIR="${LOG_DIR:-/var/log/isgb}"
LOG_FILE="${LOG_DIR}/sa-learn.log"

mkdir -p "${LOG_DIR}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SA-LEARN] $*" | tee -a "${LOG_FILE}"
}

# Prüft ob ein Verzeichnis mindestens eine Datei enthält
dir_has_files() {
    [ -d "$1" ] && [ -n "$(find "$1" -mindepth 1 -maxdepth 1 2>/dev/null | head -1)" ]
}

log "=== Starte SpamAssassin Lernlauf ==="
learned=0

if dir_has_files "${SPAM_DIR}"; then
    log "Lerne Spam aus: ${SPAM_DIR}"
    if sa-learn --spam "${SPAM_DIR}" >> "${LOG_FILE}" 2>&1; then
        learned=1
        log "Spam-Training erfolgreich abgeschlossen."
    else
        log "WARNUNG: sa-learn --spam schlug fehl"
    fi
else
    log "Spam-Verzeichnis leer/nicht vorhanden: ${SPAM_DIR}"
fi

if dir_has_files "${HAM_DIR}"; then
    log "Lerne Ham aus: ${HAM_DIR}"
    if sa-learn --ham "${HAM_DIR}" >> "${LOG_FILE}" 2>&1; then
        learned=1
        log "Ham-Training erfolgreich abgeschlossen."
    else
        log "WARNUNG: sa-learn --ham schlug fehl"
    fi
else
    log "Ham-Verzeichnis leer/nicht vorhanden: ${HAM_DIR}"
fi

if [ "${learned}" -eq 1 ]; then
    log "Synchronisiere Bayes-Datenbank..."
    if ! sa-learn --sync >> "${LOG_FILE}" 2>&1; then
        log "WARNUNG: sa-learn --sync schlug fehl"
    fi
    log "Lernlauf und Datenbanksynchronisierung abgeschlossen."
else
    log "Keine Lerndaten vorhanden. Lerndateien ablegen in:"
    log "  Spam: ${SPAM_DIR}"
    log "  Ham:  ${HAM_DIR}"
fi

log "=== Lernlauf beendet ==="
