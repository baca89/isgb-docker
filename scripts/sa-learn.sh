#!/bin/bash

# Skript: sa-learn.sh
# Daily Spamassasin Training-Job for ISGB Docker Container

CRON=1

test -f /etc/default/spamassassin && . /etc/default/spamassassin
test -x /usr/bin/sa-update || exit 0
test -x /etc/init.d/spamassassin || exit 0

if [ "$CRON" -eq 0 ]; then
    exit 0
fi

die_with_lint(){
    su - debian-spamd -c "spamassassin --lint 2>&1"
    exit 1
}

do_compile(){
    if [-x /usr/bin/re2c -a -x /usr/bin/sa-compile ]; then
        su - debian-spamd -c "sa-compile --quiet"
        chmod -R go-w,go+rX /var/lib/spamassassin/compiled
    fi
}

reload(){
    if which invoke-rc.d > /dev/null 2>&1; then
        invoke-rc.d spamassassin reload > /dev/null
    else
        /etc/init.d/spamassassin reload > /dev/null
    fi
    if [ -d /etc/spamassassin/sa-update-hooks.d ]; then
        run-parts --lsbsysinit /etc/spamassassin/sa-update-hooks.d
    fi
}

# sleep for 3600 seconds
RANGE=3600
number='od -vAn -N2 -tu4 </dev/urandom'
number='expr $number % $RANGE'
sleep $number

#update
unmask 022
su - debiam-spamd -c "sa-update --gpghomedir /var/lib/spamassassin/sa-update-keys"
su - debian-spamd -c "sa-update --nogpg --channel spamassassin.heinleich-suppoer.de"

case $? in
    0)
        su - debian-spamd -c "spamassassin --lint" || die_with_lint
        do_compile
        reload
        ;;
    1)
        exit 0
        ;;
    2)
        die_with_lint
        ;;
    *)
        echo "sa-update failed with unknown error code $?"
        ;;
esac