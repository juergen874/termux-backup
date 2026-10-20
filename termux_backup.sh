#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Termux Backup & Restore Script
# ==============================================================================
# Erstellt komprimierte Backups von Termux (Home oder Komplettsystem) mit
# Zeitstempel im Dateinamen und bietet eine geführte Wiederherstellungsoption.
# ==============================================================================

set -eo pipefail

# Farbcodes für lesbare Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Pfade
TERMUX_FILES="/data/data/com.termux/files"
TERMUX_HOME="${HOME:-/data/data/com.termux/files/home}"
TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

# Standard-Speicherort für Backups (Android Download-Ordner)
STORAGE_DIR="${TERMUX_HOME}/storage/downloads"
BACKUP_DIR="${STORAGE_DIR}"
SDCARD_FALLBACK="/sdcard/Download"

# Logging-Funktionen
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[ERFOLG]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARNUNG]${NC} $1"
}

log_error() {
    echo -e "${RED}[FEHLER]${NC} $1"
}

# ------------------------------------------------------------------------------
# 1. Speicherzugriff prüfen & einrichten
# ------------------------------------------------------------------------------
check_storage() {
    log_info "Prüfe Zugriff auf Android-Download-Ordner..."

    local storage_ready=false

    # 1. Prüfen, ob ~/storage/downloads existiert und beschreibbar ist
    if [ -d "${STORAGE_DIR}" ] && [ -w "${STORAGE_DIR}" ]; then
        BACKUP_DIR="${STORAGE_DIR}"
        storage_ready=true
    # 2. Prüfen, ob /sdcard/Download direkt beschreibbar ist
    elif [ -d "/sdcard/Download" ] && [ -w "/sdcard/Download" ]; then
        BACKUP_DIR="${SDCARD_FALLBACK}"
        storage_ready=true
    fi

    # Wenn kein Speicherzugriff vorhanden ist, termux-setup-storage anbieten/ausführen
    if [ "${storage_ready}" = false ]; then
        log_warn "Kein Schreibzugriff auf den Android-Download-Ordner vorhanden."
        if command -v termux-setup-storage >/dev/null 2>&1; then
            log_info "Starte 'termux-setup-storage'..."
            termux-setup-storage || true
            echo -e "${YELLOW}Hinweis: Bitte gewähre Termux in Android die Speicherberechtigung (Popup).${NC}"
            if [ -t 0 ]; then
                echo -n "Drücke [ENTER], nachdem du die Berechtigung erteilt hast (oder überspringe mit [ENTER])..."
                read -r -t 10 || true
            fi
        fi

        # Erneuter Test nach Aufruf von termux-setup-storage
        if [ -d "${STORAGE_DIR}" ] && [ -w "${STORAGE_DIR}" ]; then
            BACKUP_DIR="${STORAGE_DIR}"
            storage_ready=true
        elif [ -d "/sdcard/Download" ] && [ -w "/sdcard/Download" ]; then
            BACKUP_DIR="${SDCARD_FALLBACK}"
            storage_ready=true
        else
            BACKUP_DIR="${TERMUX_HOME}/TermuxBackups"
            log_warn "Download-Ordner nicht verfügbar. Verwende lokales Verzeichnis: ${BACKUP_DIR}"
        fi
    fi

    # Verzeichnis anlegen
    mkdir -p "${BACKUP_DIR}" 2>/dev/null || {
        BACKUP_DIR="${TERMUX_HOME}/TermuxBackups"
        mkdir -p "${BACKUP_DIR}"
    }

    log_success "Backup-Verzeichnis: ${BACKUP_DIR}"
}

# ------------------------------------------------------------------------------
# 2. Backup erstellen (Home-Verzeichnis oder Vollständig)
# ------------------------------------------------------------------------------
create_backup() {
    local backup_type="${1:-home}" # "home" oder "full"
    check_storage

    local timestamp
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    local archive_name
    local target_archive

    echo ""
    echo -e "${BOLD}${CYAN}=== Backup wird vorbereitet ===${NC}"

    if [ "${backup_type}" == "full" ]; then
        archive_name="termux_full_backup_${timestamp}.tar.gz"
        target_archive="${BACKUP_DIR}/${archive_name}"
        log_info "Erstelle VOLLSTÄNDIGES Backup (Home + installierte Pakete)..."
        log_info "Ziel: ${target_archive}"
        echo ""

        # Vollständiges Backup: home und usr (Prefix)
        # Excludes: storage-Symlinks, Backups-Ordner, Cache, temporäre Dateien
        tar -czvf "${target_archive}" \
            -C "${TERMUX_FILES}" \
            --exclude='./home/storage' \
            --exclude='./home/TermuxBackups' \
            --exclude='./home/.cache' \
            --exclude='./home/.gemini/antigravity-cli/brain' \
            --exclude='./usr/tmp' \
            --exclude='./usr/var/cache' \
            ./home ./usr || [ $? -eq 1 ]
    else
        archive_name="termux_home_backup_${timestamp}.tar.gz"
        target_archive="${BACKUP_DIR}/${archive_name}"
        log_info "Erstelle HOME-Backup (Dateien, Skripte, Dotfiles)..."
        log_info "Ziel: ${target_archive}"
        echo ""

        # Home-Backup: Nur Inhalt von $HOME
        tar -czvf "${target_archive}" \
            -C "${TERMUX_HOME}" \
            --exclude='./storage' \
            --exclude='./TermuxBackups' \
            --exclude='./.cache' \
            --exclude='./.gemini/antigravity-cli/brain' \
            . || [ $? -eq 1 ]
    fi

    echo ""
    # Integritätsprüfung
    log_info "Prüfe Archiv-Integrität..."
    if tar -tzf "${target_archive}" >/dev/null 2>&1; then
        local file_size
        file_size=$(du -h "${target_archive}" | cut -f1)
        # SHA256 Prüfsumme generieren
        if command -v sha256sum >/dev/null 2>&1; then
            (cd "${BACKUP_DIR}" && sha256sum "${archive_name}" > "${archive_name}.sha256")
        fi
        log_success "Backup erfolgreich abgeschlossen!"
        echo -e "${BOLD}Datei: ${GREEN}${target_archive}${NC}"
        echo -e "${BOLD}Größe: ${CYAN}${file_size}${NC}"
    else
        log_error "Das erstellte Archiv scheint beschädigt zu sein!"
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# 3. Vorhandene Backups auflisten
# ------------------------------------------------------------------------------
list_backups() {
    check_storage
    echo ""
    echo -e "${BOLD}${CYAN}=== Verfügbare Backups ===${NC}"
    
    local backups=( "${BACKUP_DIR}"/termux_*_backup_*.tar.gz )
    if [ ! -e "${backups[0]}" ]; then
        log_warn "Keine Backups im Verzeichnis gefunden."
        return 1
    fi

    local index=1
    for file in "${BACKUP_DIR}"/termux_*_backup_*.tar.gz; do
        if [ -f "${file}" ]; then
            local fname
            fname=$(basename "${file}")
            echo -e "  ${BOLD}[${index}]${NC} ${fname}"
            ((index++))
        fi
    done
    echo ""
    return 0
}

# ------------------------------------------------------------------------------
# 4. Backup wiederherstellen (Restore)
# ------------------------------------------------------------------------------
restore_backup() {
    local specific_file="$1"
    local restore_archive=""

    check_storage

    if [ -n "${specific_file}" ]; then
        if [ -f "${specific_file}" ]; then
            restore_archive="${specific_file}"
        elif [ -f "${BACKUP_DIR}/${specific_file}" ]; then
            restore_archive="${BACKUP_DIR}/${specific_file}"
        else
            log_error "Datei '${specific_file}' nicht gefunden!"
            exit 1
        fi
    else
        echo ""
        echo -e "${BOLD}${CYAN}=== Backup-Wiederherstellung ===${NC}"
        
        local backup_list=()
        for file in "${BACKUP_DIR}"/termux_*_backup_*.tar.gz; do
            if [ -f "${file}" ]; then
                backup_list+=("${file}")
            fi
        done

        if [ ${#backup_list[@]} -eq 0 ]; then
            log_error "Keine Backups in ${BACKUP_DIR} gefunden."
            return 1
        fi

        list_backups

        echo -n "Wähle die Nummer des Backups (1-${#backup_list[@]}) oder [0] zum Abbrechen: "
        read -r choice

        if [[ ! "${choice}" =~ ^[0-9]+$ ]] || [ "${choice}" -eq 0 ] || [ "${choice}" -gt ${#backup_list[@]} ]; then
            log_info "Wiederherstellung abgebrochen."
            return 0
        fi

        restore_archive="${backup_list[$((choice-1))]}"
    fi

    echo ""
    log_info "Ausgewähltes Archiv: ${restore_archive}"
    
    # Prüfe Integrität
    log_info "Prüfe Archiv-Integrität vor dem Entpacken..."
    if ! tar -tzf "${restore_archive}" >/dev/null 2>&1; then
        log_error "Archiv ist beschädigt oder kein gültiges tar.gz-Archiv!"
        exit 1
    fi
    log_success "Archiv ist intakt."

    # Bestätigung anfordern
    echo ""
    echo -e "${RED}${BOLD}ACHTUNG:${NC} Die Wiederherstellung überschreibt bestehende Dateien!"
    echo -n "Möchtest du wirklich fortfahren? (ja/nein): "
    read -r confirm

    if [ "${confirm}" != "ja" ] && [ "${confirm}" != "j" ] && [ "${confirm}" != "yes" ] && [ "${confirm}" != "y" ]; then
        log_info "Wiederherstellung abgebrochen."
        return 0
    fi

    echo ""
    log_info "Wiederherstellung wird durchgeführt..."

    # Erkennen, ob es sich um ein Full-Backup oder Home-Backup handelt
    if tar -tf "${restore_archive}" | grep -q '^\./usr/' || tar -tf "${restore_archive}" | grep -q '^usr/'; then
        log_info "Erkannt: Vollständiges Backup (Home + Usr)."
        tar -xzvf "${restore_archive}" -C "${TERMUX_FILES}" --preserve-permissions
    else
        log_info "Erkannt: Home-Verzeichnis Backup."
        tar -xzvf "${restore_archive}" -C "${TERMUX_HOME}" --preserve-permissions
    fi

    echo ""
    log_success "Wiederherstellung erfolgreich abgeschlossen!"
    echo -e "${YELLOW}Hinweis: Starte Termux ggf. neu, damit alle Änderungen wirksam werden.${NC}"
}

# ------------------------------------------------------------------------------
# 5. Interaktives Hauptmenü
# ------------------------------------------------------------------------------
show_menu() {
    while true; do
        echo ""
        echo -e "${BOLD}${CYAN}===============================================${NC}"
        echo -e "${BOLD}${CYAN}           TERMUX BACKUP & RESTORE             ${NC}"
        echo -e "${BOLD}${CYAN}===============================================${NC}"
        echo -e "  ${BOLD}[1]${NC} Home-Backup erstellen (Dateien & Dotfiles)"
        echo -e "  ${BOLD}[2]${NC} Vollständiges Backup (Home + installierte Pakete)"
        echo -e "  ${BOLD}[3]${NC} Vorhandene Backups anzeigen"
        echo -e "  ${BOLD}[4]${NC} Backup wiederherstellen (Restore)"
        echo -e "  ${BOLD}[5]${NC} Speicherberechtigung einrichten (termux-setup-storage)"
        echo -e "  ${BOLD}[0]${NC} Beenden"
        echo -e "${BOLD}${CYAN}===============================================${NC}"
        echo -n "Bitte Option wählen (0-5): "
        read -r option

        case "${option}" in
            1)
                create_backup "home"
                ;;
            2)
                create_backup "full"
                ;;
            3)
                list_backups || true
                ;;
            4)
                restore_backup ""
                ;;
            5)
                termux-setup-storage
                log_info "Speicher-Einrichtung aufgerufen. Prüfe Speicher..."
                check_storage
                ;;
            0)
                echo "Auf Wiedersehen!"
                exit 0
                ;;
            *)
                log_error "Ungültige Option. Bitte 0 bis 5 eingeben."
                ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# 6. Befehlszeilen-Parameter Verarbeitung
# ------------------------------------------------------------------------------
show_help() {
    echo "Verwendung: $0 [OPTION]"
    echo ""
    echo "Optionen:"
    echo "  -h, --home          Erstellt ein Backup des Home-Verzeichnisses"
    echo "  -f, --full          Erstellt ein vollständiges Backup (Home + Pakete)"
    echo "  -r, --restore [DAT] Stellt ein Backup wieder her (interaktiv oder Datei)"
    echo "  -l, --list          Listet vorhandene Backups auf"
    echo "  -s, --setup-storage Richtet den Speicherzugriff ein"
    echo "  --help              Zeigt diese Hilfe an"
    echo ""
    echo "Ohne Optionen wird das interaktive Menü gestartet."
}

# Argumente auswerten
if [ $# -eq 0 ]; then
    show_menu
else
    case "$1" in
        -h|--home)
            create_backup "home"
            ;;
        -f|--full)
            create_backup "full"
            ;;
        -r|--restore)
            restore_backup "$2"
            ;;
        -l|--list)
            list_backups || true
            ;;
        -s|--setup-storage)
            termux-setup-storage
            check_storage
            ;;
        --help)
            show_help
            ;;
        *)
            log_error "Unbekannter Parameter: $1"
            show_help
            exit 1
            ;;
    esac
fi
