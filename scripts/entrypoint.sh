#!/bin/bash
set -e

# Entrypoint-Skript for ISGB Docker Container

# output colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $*"
}


touch /INIT

# rsyslog is optional in containers and often cannot read /proc/kmsg without extra caps.
log_info "Überspringe rsyslog-Start im Containerbetrieb"

if [ "$(ps axf | grep -c -E "[s]pamd")" -eq 0 ]; then
  if command -v spamd >/dev/null 2>&1; then
    spamd -d --pidfile /run/spamd.pid --syslog=stderr || log_warn "spamd konnte nicht gestartet werden"
  elif [ -x /etc/init.d/spamassassin ]; then
    /etc/init.d/spamassassin start || log_warn "spamassassin init-Skript fehlgeschlagen"
  else
    log_warn "Kein spamd Startkommando gefunden"
  fi
fi

while true; do
  
    if [ -f /INIT ]; then
      /etc/cron.daily/sa_learn.sh --force-expire -D || log_warn "sa-learn Initiallauf fehlgeschlagen"

      sa-update --nogpg --channel spamassassin.heinlein-support.de || log_warn "sa-update (Heinlein-Channel) fehlgeschlagen"
      sa-update || log_warn "sa-update fehlgeschlagen"


        rm /INIT
        log_info "Initialer Lernlauf beim Containerstart..."
    fi

    isbg \
        --teachonly \
        --imaphost="$MAILSERVER" \
        --imapport="$MAILPORT" \
        --imapuser="$MAILUSER" \
        --imappass="$MAILPASS" \
        --use-ssl="$MAILSSL" \
        --learnspambox="$INBOX" \
        --learnhambox="$HAMBOX" \
        --learnthendestroy \
        --noninteractive || log_warn "isbg teachonly Durchlauf fehlgeschlagen"

    isbg \
        --flag \
        --imaphost="$MAILSERVER" \
        --imapport="$MAILPORT" \
        --imapuser="$MAILUSER" \
        --imappass="$MAILPASS" \
        --use-ssl="$MAILSSL" \
        --imapinbox="$INBOX" \
        --imapspambox="$SPAMBOX" \
        --noninteractive || log_warn "isbg flag Durchlauf fehlgeschlagen"

    sleep 60

done | tee -a /var/log/spam.log