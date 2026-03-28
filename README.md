# isGB Spam Filter Docker Image

Ein professionelles Docker-Image für **isGB Spamfilter** mit Support für mehrere Postfächer über gemountete Config-Dateien.

## Features

- 🐳 **Docker-basiert**: Einfaches Deployment und portables Setup
- 📧 **Multi-Mailbox-Support**: Unterstütze unbegrenzte Postfächer
- 📁 **Config-Volumes**: Externe Konfigurationsdateien pro Postfach
- 🔄 **GitHub Actions CI/CD**: Automatisches Bauen und Release
- 🔒 **Sicherheit**: Non-root Benutzer, Security Scanning mit Trivy
- 📊 **Logging**: Strukturiertes Logging mit verschiedenen Log-Levels
- ❤️ **Health Checks**: Container-Health-Monitoring
- 🎯 **Maschinelles Lernen**: Bayessche Spam-Filterung mit Auto-Learning

## Voraussetzungen

- Docker >= 20.10
- Docker Compose >= 1.29 (optional)
- GIT

## Quick Start

### 1. Repository klonen

```bash
git clone https://github.com/your-username/isgb-docker.git
cd isgb-docker
```

### 2. Konfiguration erstellen

Kopiere die Beispiel-Konfiguration für jedes Postfach:

```bash
# Für Postfach 1
cp config/example.conf config/user1@example.com.conf
# Für Postfach 2
cp config/example.conf config/user2@example.com.conf
```

Bearbeite die Config-Dateien und füge deine Anmeldedaten ein:

```bash
nano config/user1@example.com.conf
```

### 3. Container starten mit Docker Compose

```bash
docker-compose up -d
```

Oder mit Docker CLI:

```bash
docker build -t isgb:latest .
docker run -d \
  --name isgb-spamfilter \
  -v $(pwd)/config:/etc/isgb/mailboxes:ro \
  -v isgb-logs:/var/log/isgb \
  -v isgb-data:/var/lib/isgb \
  --restart unless-stopped \
  isgb:latest
```

### 4. Logs ansehen

```bash
docker-compose logs -f isgb
# oder
docker logs -f isgb-spamfilter
```

## Konfiguration

### Config-Dateien Struktur

```
config/
├── example.conf                    # Beispiel-Template
├── user1@example.com.conf         # Postfach 1
├── user2@example.com.conf         # Postfach 2
└── user3@example.com.conf         # Postfach 3
```

Jede `.conf`-Datei repräsentiert ein zu filtrendes Postfach.

### Wichtige Config-Optionen

```ini
[mailbox]
name = user@example.com              # Eindeutiger Name
enabled = true

[connection]
host = mail.example.com              # Mail-Server
port = 993                           # IMAP Port
username = user@example.com
password = app_password              # App-Passwort verwenden!
use_ssl = true

[filter]
spam_threshold = 5.0                 # Spam-Score Grenzwert
enable_learning = true               # Maschinelles Lernen
enable_spf_check = true
enable_dkim_check = true
enable_dmarc_check = true

[actions]
move_to_folder = Spam                # Verschiebe in Spam-Ordner
delete_threshold = 8.0               # Lösche bei hohem Score
mark_as_read = false
```

## Umgebungsvariablen

Setze die folgenden Variablen im `docker-compose.yml` oder per `-e`:

| Variable | Standard | Beschreibung |
|----------|----------|-------------|
| `CONFIG_DIR` | `/etc/isgb/mailboxes` | Konfig-Verzeichnis |
| `LOG_DIR` | `/var/log/isgb` | Log-Verzeichnis |
| `LOG_LEVEL` | `INFO` | Log-Level (DEBUG, INFO, WARNING, ERROR) |
| `WORKERS` | `4` | Anzahl der Worker-Prozesse |

## Volumes

| Volume | Zweck | Schreibzugriff |
|--------|-------|---|
| `config` | Mailbox-Konfigurationen | Nein (read-only) |
| `isgb-logs` | Anwendungs-Logs | Ja |
| `isgb-data` | Spam-Datenbanken, Cache | Ja |

## Health Check

Der Container verfügt über einen automatischen Health Check:

```bash
docker ps  # Status ansehen
# HEALTHY, UNHEALTHY, oder STARTING
```

Manueller Health Check:

```bash
docker exec isgb-spamfilter curl -f http://localhost:8080/health
```

## GitHub Actions Workflows

### 1. Docker Build & Push (`docker-build-push.yml`)

Wird bei jedem Push zu `main` oder `develop` oder bei neuen Tags ausgelöst:

- Baut das Docker-Image
- Pushed zu GitHub Container Registry (ghcr.io)
- Führt Vulnerability Scanning durch (Trivy)
- Generiert automatische Tags basierend auf Branches/Tags

**Automatische Tags:**
- `latest` für main-Branch
- `develop` für develop-Branch
- `v1.0.0` für Version-Tags
- `SHA` für Commits

### 2. Release Workflow (`release.yml`)

Aktiviert bei Push von Git-Tags (Format: `v*.*.*`):

- Erstellt automatisch GitHub Release
- Generiert Changelog aus Git-History
- Veröffentlicht Release Notes
- Verlinkt Docker-Image

**Neuen Release erstellen:**

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Bilder bauen

### Lokal

```bash
# Einfach
docker build -t isgb:latest .

# Mit custom Tags
docker build -t isgb:v1.0.0 -t isgb:latest .

# Mit BuildKit (schneller)
DOCKER_BUILDKIT=1 docker build -t isgb:latest .
```

### Mit Docker Compose

```bash
docker-compose build
docker-compose build --no-cache  # Ohne Cache
```

## Logs

### Live Logs

```bash
docker-compose logs -f isgb
```

### Log-Levels

```bash
# In docker-compose.yml oder docker run
-e LOG_LEVEL=DEBUG
```

### Log-Ausgabe in Datei

```bash
# Host-Verzeichnis mounten
docker-compose logs isgb > logs.txt
```

## Sicherheit

### Best Practices

1. **App-Passwörter verwenden**
   - Verwende kein Hauptpasswort
   - Generiere App-spezifische Passwörter bei Gmail, Outlook, etc.

2. **Secrets Management**
   - Config-Dateien nicht ins Git
   - Verwende `.env` oder Docker Secrets
   - Verwende GitHub Secrets für CI/CD

3. **Berechtigungen**
   - Config-Verzeichnis: readonly mounten
   - Betreibt als non-root Benutzer (isgb:isgb)

4. **Container Security**
   - Sicherheits-Updates: `docker pull` regelmäßig
   - Vulnerability Scanning: Trivy-Scans vor Produktion
   - Resource Limits: CPU und Memory limitieren

### Vulnerability Scanning

```bash
# Lokal
docker build -t isgb:test .
trivy image isgb:test

# Im GitHub Actions (automatisch)
# Siehe docker-build-push.yml
```

## Troubleshooting

### Container startet nicht

```bash
# Logs ansehen
docker-compose logs isgb

# Manual entrypoint für Debugging
docker run -it --entrypoint /bin/bash isgb:latest
```

### Config-Fehler

```bash
# Validierung durchführen
docker-compose exec isgb validate

# Config suchen
docker-compose exec isgb find /etc/isgb/mailboxes -name "*.conf"
```

### Verbindungsprobleme

```bash
# Verbindung testen
docker-compose exec isgb curl -v -k imaps://user@mail.example.com:993

# DNS testen
docker-compose exec isgb nslookup mail.example.com
```

### Logs ansehen

```bash
# Alle Logs
docker-compose logs isgb

# Letzte 100 Zeilen
docker-compose logs --tail=100 isgb

# Spezifischer Log-Level
docker-compose logs isgb | grep ERROR
```

## Development

### Repository-Struktur

```
isgb-docker/
├── Dockerfile                     # Docker Image Definition
├── docker-compose.yml             # Docker Compose für Entwicklung
├── .dockerignore
├── .gitignore
├── scripts/
│   └── entrypoint.sh             # Container Entrypoint
├── config/
│   └── example.conf              # Beispiel-Konfiguration
├── docs/
│   ├── INSTALLATION.md
│   ├── CONFIGURATION.md
│   └── TROUBLESHOOTING.md
├── .github/
│   └── workflows/
│       ├── docker-build-push.yml # CI/CD für Builds
│       └── release.yml            # Release Automation
└── README.md
```

### Testing

```bash
# Build testen
docker build -t isgb:test .

# Entrypoint testen
docker run --rm isgb:test validate

# Befehlshilfe
docker run --rm isgb:test --help
```

## Versions-Management

Verwende [Semantic Versioning](https://semver.org/):

```
v<MAJOR>.<MINOR>.<PATCH>
v1.0.0    - Initial Release
v1.1.0    - Neue Features
v1.1.1    - Bug Fixes
v2.0.0    - Breaking Changes
```

### Version ändern

1. Update `Dockerfile` Label
2. Tag erstellen: `git tag v1.1.0`
3. Push: `git push origin v1.1.0`
4. Release wird automatisch erstellt

## Performance-Tuning

### Container-Ressourcen

```yaml
# docker-compose.yml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 2G
    reservations:
      cpus: '0.5'
      memory: 512M
```

### isGB-Einstellungen

```ini
[schedule]
run_schedule = every 5 minutes
max_messages_per_run = 100

[advanced]
worker_threads = 4
cache_size = 1000
```

## Support & Beiträge

- **Issues**: Melde Bugs auf [GitHub Issues](https://github.com/your-username/isgb-docker/issues)
- **PRs**: Wilkommen! Bitte lese [CONTRIBUTING.md](CONTRIBUTING.md)
- **Diskussionen**: [GitHub Discussions](https://github.com/your-username/isgb-docker/discussions)

## Lizenz

MIT - Siehe [LICENSE](LICENSE)

## Danksagungen

- isGB Spam Filter Team
- Docker Community

---

**Zuletzt aktualisiert**: 28. März 2026
