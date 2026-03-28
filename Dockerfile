# isGB Spamfilter Docker Image
FROM debian:bookworm-slim

LABEL maintainer="isbg@bauerc.eu"
LABEL description="Docker image for isGB spam filter with multi-mailbox support"

# Installiere erforderliche Pakete
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    wget \
    ca-certificates \
    libssl-dev \
    libffi-dev \
    spamassassin \
    cron \
    && rm -rf /var/lib/apt/lists/*

# Erstelle Arbeitsverzeichnis
WORKDIR /opt/isgb

# Installiere isGB via pip (PEP 668: --break-system-packages ist in Docker-Containern korrekt)
# hadolint ignore=DL3013
RUN pip3 install --no-cache-dir --break-system-packages isgb

# SpamAssassin: Verzeichnisse und täglicher Lernlauf via Cron
RUN mkdir -p /root/.spamassassin /var/lib/isgb/spam /var/lib/isgb/ham /var/log/isgb \
    && chmod 700 /root/.spamassassin \
    && printf '0 2 * * * root /usr/local/bin/sa-learn.sh >> /var/log/isgb/sa-learn-cron.log 2>&1\n' \
       > /etc/cron.d/isgb-salearn \
    && chmod 0644 /etc/cron.d/isgb-salearn

# Erstelle Config-Verzeichnis mit korrekten Berechtigungen
RUN mkdir -p /etc/isgb/mailboxes && \
    chmod 755 /etc/isgb/mailboxes

# Kopiere Skripte
COPY scripts/entrypoint.sh scripts/sa-learn.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/sa-learn.sh

# Volume-Mount-Punkte (Configs, persistente Daten, SpamAssassin Bayes-DB)
VOLUME ["/etc/isgb/mailboxes", "/var/lib/isgb", "/root/.spamassassin"]

# Health Check: SpamAssassin Daemon aktiv
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD ["sh", "-c", "test -s /var/run/spamd.pid"]

# Systembenutzer anlegen (für Dateibesitz im Volume)
RUN useradd -m -u 1000 isgb && chown -R isgb:isgb /opt/isgb

# SpamAssassin spamd Port (783)
EXPOSE 783

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["start"]
