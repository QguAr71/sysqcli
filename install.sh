#!/usr/bin/env sh
# ==============================================
# SysQCLI v1.0 — One-line installer
# Usage: curl -sSL https://raw.githubusercontent.com/QguAr71/sysqcli/master/install.sh | sh
# ==============================================

set -e

RED='\033[31m'; GREEN='\033[32m'; BLUE='\033[34m'; CYAN='\033[36m'; NC='\033[0m'
BOLD='\033[1m'

echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║   SysQCLI v1.0 — Installer          ║${NC}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════╝${NC}"
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

SYSCLI_ROOT="${SYSCLI_ROOT:-$HOME/.config/sysqcli}"

# Clone or update
if [ -d "$SYSCLI_ROOT/.git" ]; then
    echo -e "${BLUE}↻ Updating existing SysQCLI...${NC}"
    git -C "$SYSCLI_ROOT" pull --ff-only 2>/dev/null || echo -e "${RED}Update failed — continuing with current version${NC}"
else
    if [ -d "$SYSCLI_ROOT" ]; then
        echo -e "${RED}$SYSCLI_ROOT exists but is not a git repo. Remove it first: rm -rf $SYSCLI_ROOT${NC}"
        exit 1
    fi
    echo -e "${BLUE}↓ Cloning SysQCLI...${NC}"
    git clone --depth 1 https://github.com/QguAr71/sysqcli.git "$SYSCLI_ROOT"
fi

# Backup .zshrc if needed
if [ -f "$HOME/.zshrc" ] && ! grep -q 'SYSCLI_ROOT' "$HOME/.zshrc"; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}✓ .zshrc backed up${NC}"
fi

# Add to .zshrc
if ! grep -q 'SYSCLI_ROOT' "$HOME/.zshrc" 2>/dev/null; then
    cat >> "$HOME/.zshrc" << 'EOF'

# SysQCLI — modularna platforma ZSH
export SYSCLI_ROOT="${SYSCLI_ROOT:-$HOME/.config/sysqcli}"
source "$SYSCLI_ROOT/init.zsh"
EOF
    echo -e "${GREEN}✓ .zshrc updated${NC}"
else
    echo -e "${GREEN}✓ .zshrc already configured${NC}"
fi

# Create default ~/.sysqclirc if missing
if [ ! -f "$HOME/.sysqclirc" ]; then
    cat > "$HOME/.sysqclirc" << 'EOF'
# SysQCLI user config — uncomment to disable modules
# SYSCLI_NO_AI=1        # disable AI
# SYSCLI_NO_MONITOR=1   # disable monitoring (fkill, qhealth)
# SYSCLI_NO_VISUALS=1   # disable fastfetch/MOTD
# SYSCLI_NO_FUN=1       # disable weather utility
# SYSCLI_NO_PLUGINS=1   # disable p10k + syntax highlighting
# SYSCLI_PROFILE="laptop"  # force profile (laptop/desktop/generic)
EOF
    echo -e "${GREEN}✓ ~/.sysqclirc created (edit to customize)${NC}"
fi

echo ""
echo -e "${GREEN}${BOLD}✓ SysQCLI installed!${NC}"
echo ""
echo -e "  Start new terminal or run: ${BOLD}exec zsh${NC}"
echo -e "  Help: ${BOLD}sysqcli${NC} (or F1)"
echo -e "  Missing packages? Run: ${BOLD}qinstall${NC}"
echo ""
