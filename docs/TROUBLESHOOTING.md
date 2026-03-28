# Troubleshooting Guide - isGB Docker

LÃ¶sungen fÃ¼r hÃ¤ufig auftretende Probleme.

## Container-Probleme

### Container startet nicht

**Symptom**: `docker-compose up` zeigt Fehler oder Container endet sofort

**Diagnose**:
```bash
# Logs Ã¼berprÃ¼fen
docker-compose logs isgb

# Container-Status
docker-compose ps
```

**LÃ¶sungen**:

1. **Config-Dateien fehlen**
   ```bash
   # Config-Verzeichnis Ã¼berprÃ¼fen
   ls -la config/
   
   # Beispiel-Config erstellen
   cp config/example.conf config/user@example.com.conf
   ```

2. **Permission Denied**
   ```bash
   # Berechtigungen Ã¼berprÃ¼fen
   ls -la config/
   chmod 644 config/*.conf
   
   # Ownership Ã¼berprÃ¼fen
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
# Mit Shell starten fÃ¼r Debugging
docker run -it \
  -v $(pwd)/config:/etc/isgb/mailboxes:ro \
  isgb:latest \
  shell
```

**Inhalte Ã¼berprÃ¼fen**:
```bash
# Entrypoint-Script testen
docker run --rm isgb:latest validate

# Python-Umgebung testen
docker run --rm isgb:latest python3 --version

# AbhÃ¤ngigkeiten Ã¼berprÃ¼fen
docker run --rm isgb:latest pip3 list
```

## Konfigurationsprobleme

### Config-Datei wird nicht erkannt

**Symptom**: `No config files found in /etc/isgb/mailboxes`

**ÃœberprÃ¼fung**:
```bash
# Host-Seite
ls -la config/
file config/*.conf

# Container-Seite
docker-compose exec isgb ls -la /etc/isgb/mailboxes/
docker-compose exec isgb find /etc/isgb/mailboxes -type f
```

**LÃ¶sung**:
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

**Validierung durchfÃ¼hren**:
```bash
# Mit Python Ã¼berprÃ¼fen
docker-compose exec isgb python3 -m configparser config/user@example.com.conf

# oder manuell validieren
docker-compose run --rm isgb validate
```

**HÃ¤ufige Fehler**:
- Falsche EinrÃ¼ckung (YAML/INI)
- Fehlende Abschnitte `[mailbox]`, `[connection]`
- UngÃ¼ltige Datentypen (z.B. `port = abc` statt `port = 993`)

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

**HÃ¤ufige Ursachen**:

1. **Falscher Hostname/Port**
   ```bash
   # ÃœberprÃ¼fe Config
   nano config/user@example.com.conf
   
   # HÃ¤ufige Adressen:
   # Gmail: imap.gmail.com:993
   # Outlook: outlook.office365.com:993 oder imap-mail.outlook.com:993
   # Postfix: mail.yourdomain.com:993
   ```

2. **SSL/TLS Problem**
   ```bash
   # Zertifikat Ã¼berprÃ¼fen
   openssl s_client -connect mail.example.com:993
   
   # Im Container
   docker-compose exec isgb openssl s_client -connect mail.example.com:993
   ```

3. **Firewall blockiert**
   ```bash
   # Port Ã¼berprÃ¼fen
   sudo netstat -tulpn | grep 993
   
   # Firewall-Regel hinzufÃ¼gen (Linux)
   sudo ufw allow 993/tcp
   ```

### Authentifizierungsfehler

**Symptom**: `Authentication failed` oder `Invalid credentials`

**ÃœberprÃ¼fung**:
```bash
# Anmeldedaten Ã¼berprÃ¼fen (sicher!)
cat config/user@example.com.conf | grep password

# Mit IMAP Client testen
docker-compose exec isgb python3 << 'EOF'
import imaplib
imap = imaplib.IMAP4_SSL("mail.example.com", 993)
imap.login("user@example.com", "password")
EOF
```

**LÃ¶sungen**:

1. **App-Passwort verwenden**
   - Gmail: [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)
   - Outlook: [account.microsoft.com/security](https://account.microsoft.com/security)
   - Bei 2FA aktiviert erforderlich

2. **Passwort-Fehler**
   ```bash
   # Sonderzeichen escapen
   # Falsch: password=pass&word
   # Richtig: password=pass%26word
   
   # oder in AnfÃ¼hrungszeichen
   password = "pass&word"
   ```

3. **Benutzername-Format**
   ```bash
   # Gmail: vollstÃ¤ndige Email
   username = user@gmail.com
   
   # Manche Server: ohne Domain
   username = user  # nicht: user@domain.com
   ```

## Performance-Probleme

### Container lÃ¤uft langsam

**Symptom**: Spam-Filtering dauert zu lange

**Monitoring**:
```bash
# Ressourcen anschauen
docker stats isgb-spamfilter

# CPU/Memory Limits Ã¼berprÃ¼fen
docker inspect isgb-spamfilter | grep -A 10 MemoryLimit
```

**Optimierung**:

1. **Mehr Ressourcen**
   ```yaml
   # docker-compose.yml
   deploy:
     resources:
       limits:
         cpus: '4'        # von 2 erhÃ¶ht
         memory: 4G       # von 2G erhÃ¶ht
   ```

2. **Worker-Threads**
   ```ini
   [advanced]
   worker_threads = 8      # erhÃ¶ht von 4
   max_messages_per_run = 200  # mehr pro Lauf
   ```

3. **Cache-GrÃ¶ÃŸe**
   ```ini
   [advanced]
   cache_size = 5000       # erhÃ¶ht von 1000
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

**LÃ¶sungen**:

1. **Cache-GrÃ¶ÃŸe reduzieren**
   ```ini
   cache_size = 500  # von 1000 reduziert
   ```

2. **Weniger Worker-Threads**
   ```ini
   worker_threads = 2  # von 4 reduziert
   ```

3. **Memory Leak finden**
   ```bash
   # Speicher Ã¼ber Zeit beobachten
   watch -n 1 'docker stats --no-stream isgb-spamfilter'
   ```

## Log-Probleme

### Kein Log-Output

**Symptom**: `docker logs` ist leer

```bash
# Log-Pfad Ã¼berprÃ¼fen
docker-compose exec isgb ls -la /var/log/isgb/

# Docker-Log Ã¼berprÃ¼fen
docker-compose logs -f isgb

# Mit timestamps
docker-compose logs -f --timestamps isgb
```

### Log-Datei wÃ¤chst zu schnell

**Symptom**: `/var/log/isgb/` wird zu groÃŸ

**LÃ¶sungen**:

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

3. **Alte Logs lÃ¶schen**
   ```bash
   docker-compose exec isgb find /var/log/isgb -name "*.log" -mtime +30 -delete
   ```

## Health Check Probleme

### Health Check schlÃ¤gt fehl

**Symptom**: `docker ps` zeigt `unhealthy`

```bash
# Health Check manuell testen
docker-compose exec isgb curl -f http://localhost:8080/health || echo "Failed"

# Verbose
docker-compose exec isgb curl -v http://localhost:8080/health
```

**LÃ¶sungen**:

1. **Timeout erhÃ¶hen**
   ```yaml
   healthcheck:
     timeout: 20s  # von 10s erhÃ¶ht
   ```

2. **Health Check deaktivieren** (temporÃ¤r fÃ¼r Debugging)
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

**Symptom**: Container kÃ¶nnen nicht miteinander kommunizieren

```bash
# Netzwerk Ã¼berprÃ¼fen
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
docker system prune -a  # WARNUNG: LÃ¶scht alle unbenutzten Images
```

### Host-Restart nach Crash

**Symptom**: Container startet nicht nach Host-Neustart

**LÃ¶sung**:
```yaml
# docker-compose.yml
restart: unless-stopped
```

```bash
# oder mit Docker CLI
docker run --restart unless-stopped ...
```

## Sicherheitsprobleme

### Permission Denied fÃ¼r Config

**Symptom**: `Permission denied` beim Lesen der Config

```bash
# Berechtigungen Ã¼berprÃ¼fen
ls -la config/

# Correct permissions
chmod 644 config/*.conf
chown 1000:1000 config/

# Container-User Ã¼berprÃ¼fen
docker-compose exec isgb id
```

### Passwort im Klartext in Logs?

**ÃœberprÃ¼fung**:
```bash
docker-compose logs | grep -i password
```

**Wenn Passwort sichtbar**: Sofort Ã¤ndern!

**Vermeidung**:
- Verwende `<<` fÃ¼r multi-line Secrets
- Logs reduzieren: `LOG_LEVEL: WARNING`
- Sensitive Config nicht in DEBUG logs

## WeiterfÃ¼hrende Hilfe

### Debugging aktivieren

```yaml
# docker-compose.yml
environment:
  LOG_LEVEL: DEBUG
```

### Bash Shell fÃ¼r Debugging

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

1. Logs speichern (ohne PasswÃ¶rter!)
2. [GitHub Issue](https://github.com/baca89/isgb-docker/issues) erstellen
3. Logs, Konfiguration, Fehler-Output anhÃ¤ngen

---

**Weitere Hilfe**: [GitHub Discussions](https://github.com/baca89/isgb-docker/discussions)
