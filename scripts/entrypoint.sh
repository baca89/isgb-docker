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

if [ "$(ps axf | grep -c -E "[r]syslog(d)?")" -eq 0 ]; then
  if command -v rsyslogd >/dev/null 2>&1; then
    rsyslogd || log_warn "rsyslogd konnte nicht gestartet werden"
  elif [ -x /etc/init.d/rsyslog ]; then
    /etc/init.d/rsyslog start || log_warn "rsyslog init-Skript fehlgeschlagen"
  else
    log_warn "Kein rsyslog Startkommando gefunden; fahre ohne rsyslog fort"
  fi
fi

if [ "$(ps axf | grep -c -E "[s]pamd")" -eq 0 ]; then
  if command -v spamd >/dev/null 2>&1; then
    spamd -d --pidfile /run/spamd.pid || log_warn "spamd konnte nicht gestartet werden"
  elif [ -x /etc/init.d/spamassassin ]; then
    /etc/init.d/spamassassin start || log_warn "spamassassin init-Skript fehlgeschlagen"
  else
    log_warn "Kein spamd Startkommando gefunden"
  fi
fi

while true; do
  
    if [ -f /INIT ]; then
        sa-learn.sh --force-expire -D

        sa-update --nogpg --channel spamassassin.heinleich-suppoer.de
        sa-update


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
        --noninteractive

    isbg \
        --flag \
        --imaphost="$MAILSERVER" \
        --imapport="$MAILPORT" \
        --imapuser="$MAILUSER" \
        --imappass="$MAILPASS" \
        --use-ssl="$MAILSSL" \
        --imapinbix="$INBOX" \
        --imapspambox="$SPAMBOX" \
        --noninteractive

    sleep 60

done | tee -a /var/log/spam.log