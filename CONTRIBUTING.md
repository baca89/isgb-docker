# Beitragen zu isGB Docker

Danke dass du zu diesem Projekt beitragen möchtest! Hier ist eine Anleitung wie du helfen kannst.

## Code of Conduct

Dieses Projekt unterliegt unserem [Code of Conduct](CODE_OF_CONDUCT.md). Durch die Teilnahme verpflichtest du dich, diesen zu respektieren.

## Wie kann ich beitragen?

### 1. Bugs melden

Hast du einen Bug gefunden? Erstelle ein [GitHub Issue](https://github.com/your-username/isgb-docker/issues) mit:

- **Titel**: Klare, kurze Beschreibung
- **Beschreibung**: Was ist das Problem?
- **Reproduzierungsschritte**: Wie kann man es reproduzieren?
- **Erwartetes Verhalten**: Was sollte passieren?
- **Aktuelles Verhalten**: Was passiert stattdessen?
- **Umgebung**: Docker-Version, OS, isGB-Version

**Beispiel:**
```
Title: Container startet nicht mit custom Config

Description:
Wenn ich eine custom Config-Datei mounte, crasht der Container...

Steps to reproduce:
1. Config-Datei erstellen
2. `docker run ... -v config.conf:...`
3. Container starten

Expected: Container startet
Actual: Container Exit mit Code 1

Environment:
- Docker 24.0
- Ubuntu 22.04
- isGB v2.1.0
```

### 2. Features vorschlagen

Hast du einer Idee für ein neues Feature? Erstelle ein [GitHub Issue](https://github.com/your-username/isgb-docker/issues) mit Tag `enhancement`:

```
Title: Feature: Support für Redis-Cache

Description:
Für bessere Performance könnte isGB Redis für Caching nutzen...

Proposed solution:
- Environment-Variable `REDIS_URL` hinzufügen
- Cache-Konfiguration in der Config-Datei
```

### 3. Code beitragen

#### Vorbereitung

1. **Fork das Repository**
   ```bash
   # Auf GitHub, "Fork" Button klicken
   ```

2. **Clone deinen Fork**
   ```bash
   git clone https://github.com/your-username/isgb-docker.git
   cd isgb-docker
   ```

3. **Remote upstream hinzufügen**
   ```bash
   git remote add upstream https://github.com/original-owner/isgb-docker.git
   ```

4. **Branch erstellen**
   ```bash
   git checkout -b feature/my-feature
   ```

#### Code-Stil

- **Dockerfile**: Folge Best Practices
  - Nutze offizielle Base-Images
  - Multi-stage Builds für kleinere Images
  - Health Checks definieren
  - Keine Root-User

- **Bash-Skripte**: 
  - ShellCheck verwenden
  - Mit `set -e` beginnen
  - Fehlerbehandlung
  - Dokumentation in Kommentaren

- **YAML (GitHub Actions)**:
  - Proper Indentation (2 Spaces)
  - Verständliche Step-Namen
  - Kommentare für komplexe Logik

- **Dokumentation**:
  - Markdown-Formatierung
  - Klare, prägnante Sprache
  - Code-Beispiele
  - Links zu relevanter Dokumentation

#### Commits

1. **Commits regelmäßig machen**
   ```bash
   git add .
   git commit -m "feat: Add Redis cache support"
   ```

2. **Commit-Nachrichten Format**
   ```
   <type>(<scope>): <subject>

   <body>

   <footer>
   ```

   **Types**: feat, fix, docs, style, refactor, test, chore, ci

   **Beispiele:**
   ```
   feat(dockerfile): Add health check for Python app
   fix(entrypoint): Fix config validation error handling
   docs(readme): Update installation instructions
   ```

3. **Upstream synchronisieren**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

4. **Push zum Fork**
   ```bash
   git push origin feature/my-feature
   ```

#### Pull Request

1. **PR auf GitHub erstellen**
   - GitHub wird dir einen PR erstellen Button anzeigen
   - Beschreibe deine Änderungen
   - Referenziere relevante Issues (#123)

2. **PR-Description-Template**
   ```markdown
   ## Description
   Kurze Beschreibung was diese PR macht

   ## Related Issue
   Fixes #123
   
   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update

   ## How Has This Been Tested?
   Beschreibe wie du die Änderungen getestet hast

   ## Checklist
   - [ ] Code folgt dem Style Guide
   - [ ] Tests geschrieben/aktualisiert
   - [ ] Dokumentation aktualisiert
   - [ ] Keine Warnmeldungen
   ```

### 4. Tests schreiben

Tests helfen um Regressions zu vermeiden:

```bash
# Test das Dockerfile mit verschiedenen Konfigurationen
docker build -t isgb:test .
docker run --rm -v $(pwd)/config:/etc/isgb/mailboxes isgb:test validate

# Test das Entrypoint-Skript
docker run --rm -v $(pwd)/config:/etc/isgb/mailboxes isgb:test shell
```

### 5. Dokumentation schreiben

Dokumentation ist Code! Hilf dabei:

- README.md aktualisieren
- Neue Features dokumentieren
- Troubleshooting-Guide erweitern
- Typos fixen

## Review Process

1. **Automatische Checks**
   - GitHub Actions Workflows müssen passen
   - Linting must pass
   - Tests müssen erfolgreich sein

2. **Code Review**
   - Mindestens ein Maintainer muss reviewen
   - Feedback geben zu:
     - Code-Qualität
     - Best Practices
     - Performance
     - Sicherheit

3. **Merge**
   - Nach Approval durch Maintainer
   - Branch wird automatisch gelöscht

## Git-Workflow

### Feature Branch
```bash
# Feature Branch
git checkout -b feature/add-monitoring

# Commits
git commit -m "feat: Add Prometheus metrics"

# Push
git push origin feature/add-monitoring

# PR erstellen auf GitHub
```

### Bug Fix Branch
```bash
git checkout -b fix/health-check-timeout

git commit -m "fix: Increase health check timeout

The current timeout is too aggressive for slow systems.
Fixes #456"

git push origin fix/health-check-timeout
```

### Documentation Branch
```bash
git checkout -b docs/performance-guide

git commit -m "docs: Add performance tuning guide"

git push origin docs/performance-guide
```

## Releases

Releases folgen [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes (v1.0.0 -> v2.0.0)
- **MINOR**: Neue Features (v1.0.0 -> v1.1.0)
- **PATCH**: Bug Fixes (v1.0.0 -> v1.0.1)

```bash
# Release erstellen
git tag v1.1.0
git push origin v1.1.0
```

GitHub Actions erstellt automatisch einen Release mit Changelog.

## Development Setup

```bash
# Repository klonen
git clone https://github.com/your-username/isgb-docker.git
cd isgb-docker

# Docker bauen
docker build -t isgb:dev .

# Tests durchführen
docker-compose up -d

# Änderungen machen...

# Wieder bauen
docker-compose build --no-cache
docker-compose up -d
```

## Support

- **Fragen**: Öffne ein [GitHub Discussion](https://github.com/your-username/isgb-docker/discussions)
- **Bugs**: [GitHub Issues](https://github.com/your-username/isgb-docker/issues)
- **Sicherheit**: Email an [security@example.com](mailto:security@example.com)

## Lizenz

Indem du zu diesem Projekt beiträgst, stimmst du zu dass dein Code unter der MIT-Lizenz veröffentlicht wird.

---

**Danke dass du hilfst dieses Projekt zu verbessern!** 🎉
