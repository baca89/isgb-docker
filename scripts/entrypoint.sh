#!/bin/bash
set -e

# Entrypoint-Skript for ISGB Docker Container

# output colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color


touch /INIT

if [ $( ps axf | grep -c -E "[r]syslog" ) -eq 0 ]; then
  /etc/init.d/rsyslog start
fi

if [ $( ps axf | grep -c -E "[s]pamd" ) -eq 0 ]; then
  /etc/init.d/spamassassin start
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