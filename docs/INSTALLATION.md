# Installationsanleitung - isGB Docker

## Systemanforderungen

- Docker-Engine >= 20.10
- Docker Compose >= 1.29 (optional, aber empfohlen)
- Mindestens 2GB RAM verfügbar
- Mindestens 2 CPU-Kerne
- 10GB freier Festplattenspeicher

### Getestete Plattformen

- Ubuntu 20.04 LTS / 22.04 LTS
- Debian 11 / 12
- CentOS 8 / AlmaLinux 8
- Windows 10/11 mit Docker Desktop
- macOS mit Docker Desktop

## Installation von Docker

### Ubuntu / Debian

```bash
# Alte Docker-Versionen deinstallieren
sudo apt-get remove docker docker-engine docker.io containerd runc

# Repository-Schlüssel hinzufügen
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Repository hinzufügen
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update und Installation
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

### CentOS / RHEL

```bash
# Repository hinzufügen
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Installation
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
```

### Windows

1. [Docker Desktop für Windows](https://docs.docker.com/desktop/install/windows-install/) herunterladen
2. Installer ausführen
3. Nach Neustart Docker Desktop starten
4. WSL2 Backend ist empfohlen

### macOS

1. [Docker Desktop für Mac](https://docs.docker.com/desktop/install/mac-install/) herunterladen
2. .dmg öffnen und in Applications verschieben
3. Docker Desktop starten

## Repository vorbereiten

### 1. Repository klonen

```bash
git clone https://github.com/your-username/isgb-docker.git
cd isgb-docker
```

### 2. Verzeichnisstruktur erstellen

```bash
# Konfiguration für Postfächer
mkdir -p config
mkdir -p logs
mkdir -p data
```

### 3. Berechtigungen setzen (Linux/macOS)

```bash
# Docker-Zugriff ohne sudo
sudo usermod -aG docker $USER

# Neu anmelden oder:
newgrp docker

# Testen
docker ps
```

## Konfiguration

### Step 1: Beispiel-Config kopieren

```bash
# Für erstes Postfach
cp config/example.conf config/user1@example.com.conf

# Für weitere Postfächer (optional)
cp config/example.conf config/user2@example.com.conf
```

### Step 2: Config-Datei bearbeiten

```bash
nano config/user1@example.com.conf
```

**Erforderliche Felder:**

```ini
[mailbox]
name = user1@example.com          # Muss eindeutig sein
enabled = true

[connection]
host = mail.example.com           # z.B. imap.gmail.com
port = 993                        # Standard IMAP/SSL
username = user1@example.com
password = your_app_password      # WICHTIG: App-Passwort!
use_ssl = true
```

### Step 3: Mail-Provider konfigurieren

#### Gmail

1. [Google Account Security](https://myaccount.google.com/security) öffnen
2. 2-Faktor-Authentifizierung aktivieren
3. [App-Passwort](https://myaccount.google.com/apppasswords) generieren
4. Dieses Passwort in der Config verwenden

```ini
[connection]
host = imap.gmail.com
port = 993
username = your-email@gmail.com
password = xxxx xxxx xxxx xxxx    # 16-Zeichen App-Passwort
use_ssl = true
```

#### Outlook / Office 365

1. [Microsoft Account Security](https://account.microsoft.com/security) öffnen
2. App-Passwort generieren (falls 2FA aktiviert)
3. Konfigurieren

```ini
[connection]
host = outlook.office365.com
port = 993
username = your-email@outlook.com
password = your_app_password
use_ssl = true
```

#### Postfix / Dovecot (eigener Server)

```ini
[connection]
host = mail.your-domain.com
port = 993
username = user@your-domain.com
password = your_password
use_ssl = true
```

## Installation mit Docker Compose

### Quick Start (empfohlen)

```bash
# Image bauen
docker-compose build

# Container starten
docker-compose up -d

# Logs überprüfen
docker-compose logs -f
```

### Überprüfung

```bash
# Container-Status
docker-compose ps

# Log-Ausgabe
docker-compose logs isgb

# Health Check
docker-compose exec isgb curl http://localhost:8080/health
```

## Installation mit Docker CLI

### Schritt 1: Image bauen

```bash
docker build -t isgb:latest .
```

### Schritt 2: Container starten

```bash
docker run -d \
  --name isgb-spamfilter \
  --restart unless-stopped \
  -v $(pwd)/config:/etc/isgb/mailboxes:ro \
  -v isgb-logs:/var/log/isgb \
  -v isgb-data:/var/lib/isgb \
  -e LOG_LEVEL=INFO \
  -p 8080:8080 \
  isgb:latest
```

### Schritt 3: Verifyierung

```bash
# Container läuft?
docker ps -a | grep isgb-spamfilter

# Logs
docker logs isgb-spamfilter

# Health Check
docker exec isgb-spamfilter curl http://localhost:8080/health
```

## Aktualisierung

### Mit Docker Compose

```bash
# Repository aktualisieren
git pull origin main

# Neue Version bauen
docker-compose build --no-cache

# Container neu starten
docker-compose up -d
```

### Mit Docker CLI

```bash
# Git aktualisieren
git pull origin main

# Image neu bauen
docker build -t isgb:latest . --no-cache

# Alten Container stoppen und löschen
docker stop isgb-spamfilter
docker rm isgb-spamfilter

# Neuen Container starten
docker run -d \
  --name isgb-spamfilter \
  --restart unless-stopped \
  -v $(pwd)/config:/etc/isgb/mailboxes:ro \
  -v isgb-logs:/var/log/isgb \
  -v isgb-data:/var/lib/isgb \
  -e LOG_LEVEL=INFO \
  -p 8080:8080 \
  isgb:latest
```

## Häufige Probleme

### Docker-Daemon läuft nicht

**Problem**: `Cannot connect to the Docker daemon`

**Lösung**:
```bash
# Linux
sudo systemctl start docker

# macOS
# Starte Docker Desktop aus Applications

# Windows
# Starte Docker Desktop aus Start-Menü
```

### Permission Denied

**Problem**: `Permission denied while trying to connect to Docker daemon`

**Lösung** (Linux):
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Config-Datei nicht gefunden

**Problem**: Container crasht, weil keine `.conf` gefunden

**Lösung**:
```bash
# Config-Dateien überprüfen
ls -la config/
ls -la config/*.conf

# Config-Volume überprüfen
docker-compose exec isgb ls /etc/isgb/mailboxes/
```

### Speicher-Probleme

**Problem**: Container wird beendet, zu wenig RAM

**Lösung**:
```bash
# Container-Speicher erhöhen
docker-compose.yml anpassen:
deploy:
  resources:
    limits:
      memory: 4G  # Erhöht von 2G
```

## Nächste Schritte

1. [Konfigurationsanleitung](CONFIGURATION.md) lesen
2. [Performance-Tuning](PERFORMANCE.md) durchführen
3. [Monitoring](MONITORING.md) aufsetzen

## Support

- Dokumentation: [README.md](../README.md)
- Troubleshooting: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Issues: GitHub Issues
