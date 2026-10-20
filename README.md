<p align="center">
  <b><a href="#-english">🇬🇧 English</a></b> &nbsp;•&nbsp; <b><a href="#-deutsch">🇩🇪 Deutsch</a></b>
</p>

---

<a name="-english"></a>
# Termux Backup & Restore Tool 📦

A user-friendly, robust Bash script for **Android Termux** for quick and reliable backup and restoration of the Home directory and entire Termux environments.

![Termux](https://img.shields.io/badge/Platform-Termux%20%2F%20Android-green.svg)
![Bash](https://img.shields.io/badge/Language-Bash-blue.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

---

## ✨ Features

- **📅 Timestamped Archives**: Every archive name includes a second-accurate timestamp (e.g., `termux_home_backup_2026-08-17_15-30-00.tar.gz`).
- **🔒 Automatic SHA256 Checksums**: Automatically generates a `.sha256` verification file for every backup archive.
- **📁 Android Storage Integration**: Automatically uses the Android **Downloads folder** (`~/storage/downloads` / `/sdcard/Download`), making backups immediately visible in Android file managers and on PC via USB.
- **🛡️ Loop & Recursion Protection**: Excludes links to internal Android storage (`~/storage`) and caches to prevent endless recursion and storage bloat.
- **🔄 Guided Restore**: Step-by-step restoration with automatic backup type detection, checksum verification, and confirmation prompts.
- **💻 Interactive Menu & CLI Support**: Can be operated either via a clean interactive TUI menu or directly via command-line arguments.

---

## 📥 Installation

Clone the repository into your Termux home directory:

```bash
git clone https://github.com/juergen874/termux-backup.git
cd termux-backup
chmod +x termux_backup.sh
```

*(Optional) Create a shortcut in your home directory:*
```bash
ln -sf ~/termux-backup/termux_backup.sh ~/termux_backup.sh
```

---

## 🚀 Usage

### 1. Interactive Menu

Run the script without parameters:
```bash
./termux_backup.sh
```

```text
===============================================
           TERMUX BACKUP & RESTORE             
===============================================
  [1] Create Home backup (files & dotfiles)
  [2] Full system backup (Home + installed packages)
  [3] Show existing backups
  [4] Restore backup
  [5] Setup storage permission (termux-setup-storage)
  [0] Exit
===============================================
```

### 2. Command-Line Options (CLI)

```bash
# Backup Home directory (files, scripts, configurations)
./termux_backup.sh -h

# Full system backup (Home + all apt/pkg packages list)
./termux_backup.sh -f

# List existing backups
./termux_backup.sh -l

# Start interactive restoration
./termux_backup.sh -r

# Directly restore a specific backup file
./termux_backup.sh -r /path/to/backup.tar.gz

# Request / verify storage permissions
./termux_backup.sh -s

# Show help
./termux_backup.sh --help
```

---

## 📂 Backup Storage Location

Backups are saved by default in the Android **Downloads folder**:
- **Inside Termux:** `~/storage/downloads/`
- **In Android:** In your *Files* app under **Downloads** or accessible on PC via USB MTP.

> **Note for Android 11+:**  
> If you encounter a `Permission denied` error, ensure that Termux has "All files access" granted in Android Settings (*Apps ➔ Termux ➔ Permissions ➔ Files and media ➔ Allow management of all files*), and run `termux-setup-storage` once.

---

## 📄 License

Published under the [MIT License](LICENSE).

---
---

<a name="-deutsch"></a>
# 🇩🇪 Deutsche Beschreibung

# Termux Backup & Restore Tool 📦

Ein benutzerfreundliches, robustes Bash-Skript für **Android Termux** zur einfachen Sicherung und Wiederherstellung des Home-Verzeichnisses und kompletter Termux-Umgebungen.

![Termux](https://img.shields.io/badge/Platform-Termux%20%2F%20Android-green.svg)
![Bash](https://img.shields.io/badge/Language-Bash-blue.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

---

## ✨ Features

- **📅 Datum & Zeitstempel**: Jeder Archivname enthält einen sekundengenauen Zeitstempel (z. B. `termux_home_backup_2026-08-17_15-30-00.tar.gz`).
- **🔒 Automatische Prüfsummen**: Erzeugt für jedes Backup eine `.sha256`-Prüfsummendatei zur Verifikation.
- **📁 Android-Speicher Integration**: Nutzt automatisch den Android **Download-Ordner** (`~/storage/downloads` bzw. `/sdcard/Download`), damit Backups direkt in Android-Dateimanagern und am PC sichtbar sind.
- **🛡️ Rekursionssicher**: Schließt Verknüpfungen auf den internen Android-Speicher (`~/storage`) und Caches automatisch aus, um Daten-Schleifen und Speicheraufblähung zu verhindern.
- **🔄 Wiederherstellung (Restore)**: Geführte Wiederherstellung mit automatischer Erkennung des Backup-Typs, Integritätsprüfung und Sicherheitsabfrage.
- **💻 Interaktives Menü & CLI-Support**: Sowohl über ein klares Menü als auch direkt über Befehlszeilen-Parameter steuerbar.

---

## 📥 Installation

Klone das Repository in dein Termux-Home-Verzeichnis:

```bash
git clone https://github.com/juergen874/termux-backup.git
cd termux-backup
chmod +x termux_backup.sh
```

*(Optional) Verknüpfung im Home-Verzeichnis erstellen:*
```bash
ln -sf ~/termux-backup/termux_backup.sh ~/termux_backup.sh
```

---

## 🚀 Verwendung

### 1. Interaktives Menü

Starte das Skript ohne Parameter:
```bash
./termux_backup.sh
```

```text
===============================================
           TERMUX BACKUP & RESTORE             
===============================================
  [1] Home-Backup erstellen (Dateien & Dotfiles)
  [2] Vollständiges Backup (Home + installierte Pakete)
  [3] Vorhandene Backups anzeigen
  [4] Backup wiederherstellen (Restore)
  [5] Speicherberechtigung einrichten (termux-setup-storage)
  [0] Beenden
===============================================
```

### 2. Befehlszeilen-Optionen (CLI)

```bash
# Home-Verzeichnis sichern (Dateien, Skripte, Konfigurationen)
./termux_backup.sh -h

# Vollständiges System sichern (Home + alle apt/pkg Pakete)
./termux_backup.sh -f

# Vorhandene Backups auflisten
./termux_backup.sh -l

# Wiederherstellung starten (interaktive Auswahl)
./termux_backup.sh -r

# Bestimmte Backup-Datei direkt wiederherstellen
./termux_backup.sh -r /pfad/zum/backup.tar.gz

# Speicherberechtigung anfordern / prüfen
./termux_backup.sh -s

# Hilfe anzeigen
./termux_backup.sh --help
```

---

## 📂 Speicherort der Backups

Die Backups werden standardmäßig im Android **Download-Ordner** abgelegt:
- **In Termux:** `~/storage/downloads/`
- **In Android:** In der App *„Dateien“* / *„Eigene Dateien“* unter **Downloads** oder am PC via USB.

> **Hinweis für Android 11+:**  
> Falls beim Zugriff `Permission denied` erscheint, stelle sicher, dass Termux in den Android-Einstellungen (*Apps ➔ Termux ➔ Berechtigungen ➔ Zugriff auf alle Dateien*) die volle Speicherberechtigung besitzt, und führe einmalig `termux-setup-storage` aus.

---

## 📄 Lizenz

Dieses Projekt steht unter der [MIT License](LICENSE).
