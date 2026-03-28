# Troubleshooting Guide - isGB Docker

Lösungen für häufig auftretende Probleme.

## Container-Probleme

### Container startet nicht

**Symptom**: `docker-compose up` zeigt Fehler oder Container endet sofort

**Diagnose**:
```bash
# Logs überprüfen
docker-compose logs isgb

# Container-Status
docker-compose ps
```

**Lösungen**:

1. **Config-Dateien fehlen**
   ```bash
   # Config-Verzeichnis überprüfen
   ls -la config/
   
   # Beispiel-Config erstellen
   cp config/example.conf config/user@example.com.conf
   ```

2. **Permission Denied**
   ```bash
   # Berechtigungen überprüfen
   ls -la config/
   chmod 644 config/*.conf
   
   # Ownership überprüfen
   chown 1000:1000 config/
   ```

3. **Docker-Daemon nicht erreichbar**
   ```bash
   # Daemon starten
   sudo systemctl start docker  # Linux
   # oder Docker Desktop starten (macOS/Windows)
   ```

### Container crasht sofort nach Start

**Symptom**: Container startet, aber endet sofort mit Exit-Code

**Debug-Mode aktivieren**:
```bash
# Mit Shell starten für Debugging
docker run -it \
  -v $(pwd)/config:/etc/isgb/mailboxes:ro \
  isgb:latest \
  shell
```

**Inhalte überprüfen**:
```bash
# Entrypoint-Script testen
docker run --rm isgb:latest validate

# Python-Umgebung testen
docker run --rm isgb:latest python3 --version

# Abhängigkeiten überprüfen
docker run --rm isgb:latest pip3 list
```

## Konfigurationsprobleme

### Config-Datei wird nicht erkannt

**Symptom**: `No config files found in /etc/isgb/mailboxes`

**Überprüfung**:
```bash
# Host-Seite
ls -la config/
file config/*.conf

# Container-Seite
docker-compose exec isgb ls -la /etc/isgb/mailboxes/
docker-compose exec isgb find /etc/isgb/mailboxes -type f
```

**Lösung**:
```bash
# Config-Datei erstellen mit korrektem Format
cat > config/user@example.com.conf << 'EOF'
[mailbox]
name = user@example.com
enabled = true

[connection]
host = mail.example.com
port = 993
username = user@example.com
password = app_password
use_ssl = true
EOF

# Berechtigungen setzen
chmod 644 config/*.conf
```

### Config hat Syntax-Fehler

**Symptom**: Konfiguration wird nicht akzeptiert

**Validierung durchführen**:
```bash
# Mit Python überprüfen
docker-compose exec isgb python3 -m configparser config/user@example.com.conf

# oder manuell validieren
docker-compose run --rm isgb validate
```

**Häufige Fehler**:
- Falsche Einrückung (YAML/INI)
- Fehlende Abschnitte `[mailbox]`, `[connection]`
- Ungültige Datentypen (z.B. `port = abc` statt `port = 993`)

**Korrekte Syntax**:
```ini
[section]
key = value          # String
port = 993          # Integer
enabled = true      # Boolean
threshold = 5.0     # Float
```

## Verbindungsprobleme

### Kann sich nicht mit Mail-Server verbinden

**Symptom**: `Connection refused` oder `Connection timeout`

**Diagnose**:
```bash
# Host-Verbindung testen
telnet mail.example.com 993

# Container von innen testen
docker-compose exec isgb telnet mail.example.com 993

# DNS testen
docker-compose exec isgb nslookup mail.example.com
docker-compose exec isgb nslookup 8.8.8.8
```

**Häufige Ursachen**:

1. **Falscher Hostname/Port**
   ```bash
   # Überprüfe Config
   nano config/user@example.com.conf
   
   # Häufige Adressen:
   # Gmail: imap.gmail.com:993
   # Outlook: outlook.office365.com:993 oder imap-mail.outlook.com:993
   # Postfix: mail.yourdomain.com:993
   ```

2. **SSL/TLS Problem**
   ```bash
   # Zertifikat überprüfen
   openssl s_client -connect mail.example.com:993
   
   # Im Container
   docker-compose exec isgb openssl s_client -connect mail.example.com:993
   ```

3. **Firewall blockiert**
   ```bash
   # Port überprüfen
   sudo netstat -tulpn | grep 993
   
   # Firewall-Regel hinzufügen (Linux)
   sudo ufw allow 993/tcp
   ```

### Authentifizierungsfehler

**Symptom**: `Authentication failed` oder `Invalid credentials`

**Überprüfung**:
```bash
# Anmeldedaten überprüfen (sicher!)
cat config/user@example.com.conf | grep password

# Mit IMAP Client testen
docker-compose exec isgb python3 << 'EOF'
import imaplib
imap = imaplib.IMAP4_SSL("mail.example.com", 993)
imap.login("user@example.com", "password")
EOF
```

**Lösungen**:

1. **App-Passwort verwenden**
   - Gmail: [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)
   - Outlook: [account.microsoft.com/security](https://account.microsoft.com/security)
   - Bei 2FA aktiviert erforderlich

2. **Passwort-Fehler**
   ```bash
   # Sonderzeichen escapen
   # Falsch: password=pass&word
   # Richtig: password=pass%26word
   
   # oder in Anführungszeichen
   password = "pass&word"
   ```

3. **Benutzername-Format**
   ```bash
   # Gmail: vollständige Email
   username = user@gmail.com
   
   # Manche Server: ohne Domain
   username = user  # nicht: user@domain.com
   ```

## Performance-Probleme

### Container läuft langsam

**Symptom**: Spam-Filtering dauert zu lange

**Monitoring**:
```bash
# Ressourcen anschauen
docker stats isgb-spamfilter

# CPU/Memory Limits überprüfen
docker inspect isgb-spamfilter | grep -A 10 MemoryLimit
```

**Optimierung**:

1. **Mehr Ressourcen**
   ```yaml
   # docker-compose.yml
   deploy:
     resources:
       limits:
         cpus: '4'        # von 2 erhöht
         memory: 4G       # von 2G erhöht
   ```

2. **Worker-Threads**
   ```ini
   [advanced]
   worker_threads = 8      # erhöht von 4
   max_messages_per_run = 200  # mehr pro Lauf
   ```

3. **Cache-Größe**
   ```ini
   [advanced]
   cache_size = 5000       # erhöht von 1000
   ```

4. **Schedule optimieren**
   ```ini
   [schedule]
   run_schedule = every 10 minutes  # statt every 5 minutes
   ```

### Hohe Speichernutzung

**Symptom**: Container nutzt > 80% RAM

**Analyse**:
```bash
# Speicher-Details
docker stats --no-stream isgb-spamfilter

# Prozess-Details
docker-compose exec isgb ps aux
docker-compose exec isgb top
```

**Lösungen**:

1. **Cache-Größe reduzieren**
   ```ini
   cache_size = 500  # von 1000 reduziert
   ```

2. **Weniger Worker-Threads**
   ```ini
   worker_threads = 2  # von 4 reduziert
   ```

3. **Memory Leak finden**
   ```bash
   # Speicher über Zeit beobachten
   watch -n 1 'docker stats --no-stream isgb-spamfilter'
   ```

## Log-Probleme

### Kein Log-Output

**Symptom**: `docker logs` ist leer

```bash
# Log-Pfad überprüfen
docker-compose exec isgb ls -la /var/log/isgb/

# Docker-Log überprüfen
docker-compose logs -f isgb

# Mit timestamps
docker-compose logs -f --timestamps isgb
```

### Log-Datei wächst zu schnell

**Symptom**: `/var/log/isgb/` wird zu groß

**Lösungen**:

1. **Log-Level reduzieren**
   ```yaml
   environment:
     LOG_LEVEL: WARNING  # von INFO reduziert
   ```

2. **Log-Rotation einstellen**
   ```ini
   [logging]
   max_log_size = 10     # von 50 MB reduziert
   backup_count = 3      # von 5 reduziert
   ```

3. **Alte Logs löschen**
   ```bash
   docker-compose exec isgb find /var/log/isgb -name "*.log" -mtime +30 -delete
   ```

## Health Check Probleme

### Health Check schlägt fehl

**Symptom**: `docker ps` zeigt `unhealthy`

```bash
# Health Check manuell testen
docker-compose exec isgb curl -f http://localhost:8080/health || echo "Failed"

# Verbose
docker-compose exec isgb curl -v http://localhost:8080/health
```

**Lösungen**:

1. **Timeout erhöhen**
   ```yaml
   healthcheck:
     timeout: 20s  # von 10s erhöht
   ```

2. **Health Check deaktivieren** (temporär für Debugging)
   ```yaml
   # healthcheck:
   #   disable: true
   ```

## Docker Compose Probleme

### Volume-Mount-Fehler

**Symptom**: `mount: no such file or directory`

```bash
# Absoluten Pfad verwenden
pwd
# /home/user/isgb-docker

# docker-compose.yml anpassen
volumes:
  - /home/user/isgb-docker/config:/etc/isgb/mailboxes:ro
```

### Network-Fehler

**Symptom**: Container können nicht miteinander kommunizieren

```bash
# Netzwerk überprüfen
docker network ls
docker network inspect isgb-docker_isgb-network

# Container neu verbinden
docker-compose down
docker-compose up -d
```

## System-Probleme

### Disk Space-Probleme

**Symptom**: Container crasht `no space left on device`

```bash
# Freier Speicher
df -h

# Docker-Speicher
docker system df

# Cleanup
docker system prune -a  # WARNUNG: Löscht alle unbenutzten Images
```

### Host-Restart nach Crash

**Symptom**: Container startet nicht nach Host-Neustart

**Lösung**:
```yaml
# docker-compose.yml
restart: unless-stopped
```

```bash
# oder mit Docker CLI
docker run --restart unless-stopped ...
```

## Sicherheitsprobleme

### Permission Denied für Config

**Symptom**: `Permission denied` beim Lesen der Config

```bash
# Berechtigungen überprüfen
ls -la config/

# Correct permissions
chmod 644 config/*.conf
chown 1000:1000 config/

# Container-User überprüfen
docker-compose exec isgb id
```

### Passwort im Klartext in Logs?

**Überprüfung**:
```bash
docker-compose logs | grep -i password
```

**Wenn Passwort sichtbar**: Sofort ändern!

**Vermeidung**:
- Verwende `<<` für multi-line Secrets
- Logs reduzieren: `LOG_LEVEL: WARNING`
- Sensitive Config nicht in DEBUG logs

## Weiterführende Hilfe

### Debugging aktivieren

```yaml
# docker-compose.yml
environment:
  LOG_LEVEL: DEBUG
```

### Bash Shell für Debugging

```bash
docker-compose run --rm isgb shell

# Innen
cat /etc/isgb/mailboxes/*.conf
python3 -m ipdb
```

### Logs speichern

```bash
# Alle Logs sammeln
docker-compose logs > debug-logs.txt
docker-compose exec isgb tar czf - /var/log/isgb > isgb-logs.tar.gz
```

### Bugreport erstellen

Wenn du mit Debugging fertig bist:

1. Logs speichern (ohne Passwörter!)
2. [GitHub Issue](https://github.com/your-username/isgb-docker/issues) erstellen
3. Logs, Konfiguration, Fehler-Output anhängen

---

**Weitere Hilfe**: [GitHub Discussions](https://github.com/your-username/isgb-docker/discussions)
