# Git Workflow

## Branches & Remotes

| Branch | Remote | Repo | Inhalt |
|--------|--------|------|--------|
| `dev` | `dev/dev` | CooldownCursorManager-dev (privat) | Alles inkl. dev/ |
| `main` | `public/main` | CooldownCursorManager (public) | Nur Release-Code |

## Täglicher Workflow

### 1. Auf dev arbeiten
```bash
git checkout dev
# Änderungen machen...
git add .
git commit -m "Beschreibung der Änderung"
```

### 2. Dev pushen
```bash
git push dev
```

### 3. Release vorbereiten
Version in `CooldownCursorManager.toc` hochsetzen:
```
## Version: X.Y.Z
```

### 4. Von dev nach main mergen
```bash
git checkout main
git merge dev
git push public main
```
> GitHub Action erstellt automatisch GitHub Release `vX.Y.Z` aus der TOC-Version.

### 5. CurseForge deployen (manuell)
1. Gehe zu **GitHub → Actions → Deploy to CurseForge**
2. Klicke **Run workflow**
3. BigWigs Packager erstellt das Paket und lädt es auf CurseForge hoch

### 6. Zurück zu dev
```bash
git checkout dev
```

## Hinweise
- `dev/` Ordner ist auf main per `.gitignore` ausgeschlossen
- `.github/workflows/release.yml` erstellt automatisch einen GitHub Release (nur auf main)
- `.github/workflows/curseforge.yml` ist ein manueller Button für CurseForge Deploy
- Release wird nur erstellt wenn der Version-Tag noch nicht existiert
- `.pkgmeta` schließt `dev/`, `.pkgmeta` und `.github/` vom CurseForge-Paket aus
- GitHub Secret `CF_API_KEY` muss im public Repo hinterlegt sein
