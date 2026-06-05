#!/usr/bin/env sh
# ==============================================
# SysQCLI v1.0 — Installer / Uninstaller
# Usage:
#   curl -sSL https://.../install.sh | sh           # install
#   curl -sSL https://.../install.sh | sh -s -- --dry-run
#   curl -sSL https://.../install.sh | sh -s -- --uninstall
# ==============================================

set -e

RED='\033[31m'; GREEN='\033[32m'; BLUE='\033[34m'; CYAN='\033[36m'; YELLOW='\033[33m'; NC='\033[0m'
BOLD='\033[1m'

DRY_RUN=0
UNINSTALL=0
FORCE=0
for arg in "$@"; do
    case "$arg" in
        --dry-run)   DRY_RUN=1 ;;
        --uninstall) UNINSTALL=1 ;;
        --force|-f)  FORCE=1 ;;
    esac
done

SYSCLI_ROOT="${SYSCLI_ROOT:-$HOME/.config/sysqcli}"

# --------------- helpers ---------------
maybe() {
    if [ "$DRY_RUN" -eq 1 ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} $*"
    else
        eval "$*"
    fi
}

section() {
    echo ""
    echo -e "${CYAN}${BOLD}── $* ──${NC}"
}
# ---------------------------------------

# ═══════════════════════════════════════
# UNINSTALL
# ═══════════════════════════════════════
if [ "$UNINSTALL" -eq 1 ]; then
    if [ "$DRY_RUN" -eq 0 ] && [ "$FORCE" -eq 0 ]; then
        echo -e "${RED}${BOLD}⚠️  This will remove SysQCLI completely.${NC}"
        echo -e "   Files to remove:"
        echo -e "     - $SYSCLI_ROOT/"
        echo -e "     - $HOME/.sysqclirc"
        echo -e "     - SYSCLI_ROOT lines from .zshrc"
        echo -e "     - .zshrc.bak.* backups"
        printf "   Continue? (y/N) "
        read -r confirm
        [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && { echo "Aborted."; exit 0; }
    fi

    section "Uninstalling SysQCLI"

    # Remove from .zshrc
    if [ -f "$HOME/.zshrc" ] && grep -q 'SYSCLI_ROOT' "$HOME/.zshrc" 2>/dev/null; then
        maybe sed -i '/SYSCLI_ROOT/d;/sysqcli/d' "$HOME/.zshrc"
        echo -e "${GREEN}✓ SYSCLI_ROOT removed from .zshrc${NC}"
    else
        echo -e "${BLUE}  .zshrc clean (no SysQCLI entries)${NC}"
    fi

    # Remove sysqclirc
    if [ -f "$HOME/.sysqclirc" ]; then
        maybe rm "$HOME/.sysqclirc"
        echo -e "${GREEN}✓ ~/.sysqclirc removed${NC}"
    fi

    # Remove config directory
    if [ -d "$SYSCLI_ROOT" ]; then
        maybe rm -rf "$SYSCLI_ROOT"
        echo -e "${GREEN}✓ $SYSCLI_ROOT/ removed${NC}"
    fi

    # Remove backups
    for bak in "$HOME"/.zshrc.bak.*; do
        [ -f "$bak" ] || continue
        maybe rm "$bak"
        echo -e "${GREEN}✓ $bak removed${NC}"
    done

    echo ""
    echo -e "${GREEN}${BOLD}✓ SysQCLI uninstalled.${NC}"
    echo -e "  Restart shell: ${BOLD}exec zsh${NC}"
    exit 0
fi

# ═══════════════════════════════════════
# INSTALL
# ═══════════════════════════════════════
echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║   SysQCLI v1.0 — Installer          ║${NC}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════╝${NC}"
[ "$DRY_RUN" -eq 1 ] && echo -e "${YELLOW}${BOLD}  [ DRY RUN — no changes will be made ]${NC}"
echo ""

# Check ZSH
if ! command -v zsh >/dev/null 2>&1; then
    echo -e "${RED}ZSH is required. Install it first.${NC}"
    exit 1
fi

ZSH_VER=$(zsh --version 2>/dev/null | awk '{print $2}' | cut -d. -f1)
if [ "$ZSH_VER" -lt 5 ]; then
    echo -e "${RED}ZSH 5.8+ required. Found: $(zsh --version)${NC}"
    exit 1
fi

section "Step 1: Clone repository"

if [ -d "$SYSCLI_ROOT/.git" ]; then
    echo -e "${BLUE}↻ Updating existing SysQCLI...${NC}"
    maybe git -C "$SYSCLI_ROOT" pull --ff-only 2>/dev/null || echo -e "${RED}Update failed — continuing with current version${NC}"
else
    if [ -d "$SYSCLI_ROOT" ]; then
        echo -e "${YELLOW}$SYSCLI_ROOT exists but is not a git repo.${NC}"
        if [ "$DRY_RUN" -eq 1 ]; then
            echo -e "${YELLOW}[DRY-RUN]${NC} Would fail here on real install."
        else
            echo -e "${RED}Remove it first: rm -rf $SYSCLI_ROOT${NC}"
            exit 1
        fi
    fi
    echo -e "${BLUE}↓ Cloning SysQCLI...${NC}"
    maybe git clone --depth 1 https://github.com/QguAr71/sysqcli.git "$SYSCLI_ROOT"
fi

section "Step 2: Backup .zshrc"

if [ -f "$HOME/.zshrc" ] && ! grep -q 'SYSCLI_ROOT' "$HOME/.zshrc"; then
    maybe cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}✓ .zshrc backed up${NC}"
else
    echo -e "${BLUE}  Backupskippped (already configured or no .zshrc)${NC}"
fi

section "Step 3: Configure .zshrc"

if ! grep -q 'SYSCLI_ROOT' "$HOME/.zshrc" 2>/dev/null; then
    if [ "$DRY_RUN" -eq 1 ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Would append to .zshrc:"
        echo "  export SYSCLI_ROOT=..."
        echo "  source \$SYSCLI_ROOT/init.zsh"
    else
        cat >> "$HOME/.zshrc" << 'EOF'

# SysQCLI — modularna platforma ZSH
export SYSCLI_ROOT="${SYSCLI_ROOT:-$HOME/.config/sysqcli}"
source "$SYSCLI_ROOT/init.zsh"
EOF
        echo -e "${GREEN}✓ .zshrc updated${NC}"
    fi
else
    echo -e "${GREEN}✓ .zshrc already configured${NC}"
fi

section "Step 4: Create ~/.sysqclirc"

if [ ! -f "$HOME/.sysqclirc" ]; then
    maybe cat > "$HOME/.sysqclirc" << 'EOF'
# SysQCLI user config — uncomment to disable modules
# SYSCLI_NO_AI=1        # disable AI
# SYSCLI_NO_MONITOR=1   # disable monitoring (fkill, qhealth)
# SYSCLI_NO_VISUALS=1   # disable fastfetch/MOTD
# SYSCLI_NO_FUN=1       # disable weather utility
# SYSCLI_NO_PLUGINS=1   # disable p10k + syntax highlighting
# SYSCLI_PROFILE="laptop"  # force profile (laptop/desktop/generic)
EOF
    echo -e "${GREEN}✓ ~/.sysqclirc created (edit to customize)${NC}"
else
    echo -e "${BLUE}  ~/.sysqclirc already exists — left untouched${NC}"
fi

section "Done"

if [ "$DRY_RUN" -eq 1 ]; then
    echo -e "${YELLOW}${BOLD}  Dry run complete — no changes made.${NC}"
    echo -e "  Run without --dry-run to install."
else
    echo -e "${GREEN}${BOLD}✓ SysQCLI installed!${NC}"
fi
echo ""
echo -e "  Start new terminal or run: ${BOLD}exec zsh${NC}"
echo -e "  Help: ${BOLD}sysqcli${NC} (or F1)"
echo -e "  Missing packages? Run: ${BOLD}qinstall${NC}"
echo -e "  Uninstall:  ${BOLD}curl .../install.sh | sh -s -- --uninstall${NC}"
echo ""
