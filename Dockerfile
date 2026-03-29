FROM ubuntu

LABEL maintainer="isbg@bauerc.eu"
LABEL description="Docker image for ISBG (Intelligent Spamfilter für Gmail) with integrated SpamAssassin Daemon (spamd) and Cron for scheduled learning."

ENV DEBIAN_FRONTEND noninteractive
ENV TZ=Europe/Berlin

#dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-setuptools \
    spamassassin \
    imapfilter \
    razor \
    pyzar \
    unp \
    wget \
    unzip \
    rsyslog
    
RUN pip3 install --upgrade pip && \
    pip3 install isbg && \
    mkdir /root/.spamassassin && \
    apt-get autoremove --purge -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    python3 --version

COPY user_prefs /root/.spamassassin/user_prefs
COPY default_spamassassin /etc/default/spamassassin
COPY scripts/entrypoint.sh /entrypoint.sh
COPY scripts/sa_learn.sh /etc/cron.daily/sa_learn

CMD cron && bash /entrypoint.sh