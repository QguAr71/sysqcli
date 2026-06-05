#!/usr/bin/env zsh
# ===============================================================
# SysQCLI Config v1.0 — QPKG (Package Manager Abstraction)
# ===============================================================

_qpkg_detect() {
    command -v pacman &>/dev/null && { echo "pacman"; return; }
    command -v apt    &>/dev/null && { echo "apt"; return; }
    command -v dnf    &>/dev/null && { echo "dnf"; return; }
    command -v xbps   &>/dev/null && { echo "xbps"; return; }
    echo "unknown"
}

export SYSCLI_PM=$(_qpkg_detect)

qpkg() {
    case "$SYSCLI_PM" in
        pacman)
            case "$1" in
                install) shift; sudo pacman -S --needed "$@" ;;
                upgrade) sudo pacman -Syu ;;
                check)   checkupdates ;;
                clean)   sudo paccache -rk 1 ;;
                orphans) pacman -Qtdq ;;
                *)       echo "qpkg: nieznana akcja '$1'"; return 1 ;;
            esac
            ;;
        *)
            echo "qpkg: distro '$SYSCLI_PM' nieobsługiwane (v2 multi-distro)"
            return 1
            ;;
    esac
}
