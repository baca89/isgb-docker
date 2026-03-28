#!/bin/bash
set -e

# Entrypoint-Skript für isGB Docker Container

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CONFIG_DIR="${CONFIG_DIR:-/etc/isgb/mailboxes}"
LOG_DIR="${LOG_DIR:-/var/log/isgb}"

# Logging-Funktionen
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Überprüfe ob Config-Verzeichnis existiert
if [ ! -d "$CONFIG_DIR" ]; then
    log_error "Config-Verzeichnis nicht gefunden: $CONFIG_DIR"
    log_info "Bitte mounte das Config-Verzeichnis: -v /pfad/zu/configs:/etc/isgb/mailboxes"
    exit 1
fi

# Überprüfe ob mindestens eine Config-Datei existiert
CONFIG_COUNT=$(find "$CONFIG_DIR" -name "*.conf" 2>/dev/null | wc -l)
if [ "$CONFIG_COUNT" -eq 0 ]; then
    log_warn "Keine Config-Dateien gefunden in $CONFIG_DIR"
    log_info "Erstelle Beispiel-Config..."
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_DIR/example.conf" << 'EOF'
# isGB Spam Filter Configuration
# Duplikate diese Datei für jedes Postfach und benenne sie entsprechend

[mailbox]
# Postfach-Identifikator
name = example@example.com
host = mail.example.com
port = 993
username = example@example.com
auth_secret = [REPLACE_WITH_YOUR_PASSWORD]
use_ssl = true

[filter]
# Spam-Filter-Einstellungen
spam_threshold = 5.0
enable_learning = true
database_path = /var/lib/isgb/spam.db

[actions]
# Aktion bei erkanntem Spam
move_to_folder = Spam
mark_as_read = false
EOF
    log_info "Beispiel-Config erstellt: $CONFIG_DIR/example.conf"
fi

# Erstelle Log-Verzeichnis
mkdir -p "$LOG_DIR"

# Parse Kommando
case "${1:-start}" in
    start)
        log_info "Starte isGB Spamfilter..."
        
        # Validiere alle Config-Dateien
        log_info "Validiere Config-Dateien..."
        for config_file in "$CONFIG_DIR"/*.conf; do
            if [ -f "$config_file" ]; then
                log_info "Validiere: $(basename "$config_file")"
                # Hier könnte Validierungslogik folgen
            fi
        done
        
        log_info "isGB gestartet mit $CONFIG_COUNT Postfächern"
        log_info "Logs unter: $LOG_DIR"
        
        # Starte isGB (Platzhalter - anpassen je nach tatsächlicher isGB-Implementierung)
        # python3 /opt/isgb/isgb.py --config-dir "$CONFIG_DIR" --log-dir "$LOG_DIR"
        
        # Für Demo: einfach am Laufen halten
        tail -f /dev/null
        ;;
    
    validate)
        log_info "Validiere Config-Dateien..."
        for config_file in "$CONFIG_DIR"/*.conf; do
            if [ -f "$config_file" ]; then
                log_info "OK: $(basename "$config_file")"
            fi
        done
        ;;
    
    shell)
        log_info "Starte interaktive Shell..."
        /bin/bash
        ;;
    
    *)
        log_error "Unbekannter Befehl: $1"
        echo "Verfügbare Befehle:"
        echo "  start     - Starte isGB Spamfilter (Standard)"
        echo "  validate  - Validiere Config-Dateien"
        echo "  shell     - Öffne interaktive Shell"
        exit 1
        ;;
esac
