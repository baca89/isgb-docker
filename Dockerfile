# isGB Spamfilter Docker Image
FROM debian:bookworm-slim

LABEL maintainer="your-email@example.com"
LABEL description="Docker image for isGB spam filter with multi-mailbox support"

# Installiere erforderliche Pakete
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
    && rm -rf /var/lib/apt/lists/*

# Erstelle Arbeitsverzeichnis
WORKDIR /opt/isgb

# Klone oder installiere isGB
# Ersetze mit der tatsächlichen isGB-Installation
RUN git clone https://github.com/your-username/isgb.git . || \
    pip3 install isgb

# Erstelle Config-Verzeichnis mit korrekten Berechtigungen
RUN mkdir -p /etc/isgb/mailboxes && \
    chmod 755 /etc/isgb/mailboxes

# Kopiere Entrypoint-Skript
COPY scripts/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Erstelle Volume-Mount-Punkt
VOLUME ["/etc/isgb/mailboxes"]

# Health Check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Standardbenutzer (nicht als root)
RUN useradd -m -u 1000 isgb && chown -R isgb:isgb /opt/isgb
USER isgb

# Exponiere Port (anpassen je nach isGB-Konfiguration)
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["start"]
