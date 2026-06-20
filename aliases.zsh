#!/usr/bin/env zsh
# ===============================================================
# SysQCLI Config v1.0 — ALIASES (Commands, Navigation, System)
# ===============================================================

# ═══════════════════════════════════════════════════════════════
# PODSTAWOWE OVERRIDES
# ═══════════════════════════════════════════════════════════════
alias c='clear'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ls='lsd --color=always --icon=always --group-directories-first'
alias ll='lsd -la --header'
alias lt='lsd --tree --depth 3 --color=always'
alias cat='bat --paging=never'
alias top='btop'
alias jlog='SYSTEMD_COLORS=1 journalctl -n 50 | bat --paging=never -l log'

# eza override (jeśli dostępne)
command -v eza &>/dev/null && {
    alias l="eza -lah --icons --group-directories-first --git"
    alias lt="eza --tree --level=2 --icons"
}

# ═══════════════════════════════════════════════════════════════
# GLOBALNE ALIASY (pipe suffixes)
# ═══════════════════════════════════════════════════════════════
alias -g G='| grep --color=auto'
alias -g L='| less -RFX'
alias -g M='| micro'
alias -g NE='2>/dev/null'

# ═══════════════════════════════════════════════════════════════
# TRYBY
# ═══════════════════════════════════════════════════════════════
qsafe()      { touch "$HOME/.sysqcli_safe" && echo "\uf0c3 Safe mode — restart ZSH aby aktywować" && exec zsh }
qunsafe()    { rm -f "$HOME/.sysqcli_safe" && echo " Full mode — restart ZSH aby aktywować" && exec zsh }
qimmutable() { SYSCLI_MODE=immutable exec zsh }
qfull()      { rm -f "$HOME/.sysqcli_safe" && SYSCLI_MODE=full exec zsh }
szs()        { source "$SYSCLI_ROOT/init.zsh" && clear && echo " SysQCLI przeładowany." }

# ═══════════════════════════════════════════════════════════════
# SYSTEM
# ═══════════════════════════════════════════════════════════════
# Super update (wersja uproszczona — nie --noconfirm)
up() {
    clear
    echo -e "\e[1;36m┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\e[0m"
    echo -e "\e[1;36m┃  SysQCLI v$SYSCLI_VERSION — SUPER UPDATE                      ┃\e[0m"
    echo -e "\e[1;36m┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\e[0m"
    echo -e "\n\e[1;32m [1/4] Aktualizacja systemu (Pacman)...\e[0m"
    sudo pacman -Syu
    command -v yay &>/dev/null && { echo -e "\n\e[1;33m AUR (Yay)...\e[0m"; yay -Sua; }

    echo -e "\n\e[1;33m [2/4] Czyszczenie...\e[0m"
    sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null || echo "Brak sierot."
    sudo paccache -rk 1 2>/dev/null && sync

    echo -e "\n\e[1;34m [3/4] Aktualizacja modeli AI (Ollama)...\e[0m"
    command -v ollama &>/dev/null && for m in qwen2.5:7b qwen2.5:14b deepseek-coder-v2:16b; do
        echo " Pull $m..."
        ollama pull "$m" 2>/dev/null
    done

    echo -e "\n\e[1;35m [4/4] Rekompilacja Zsh...\e[0m"
    zcompile "$SYSCLI_ROOT"/*.zsh 2>/dev/null

    echo -e "\e[1;32m System lśni, $USER.\e[0m"
}

# Tylko aktualizacja pacman (bez AI, bez sprzątania)
qupdate() { sudo pacman -Syu }

# Clean
clean() {
    echo " Sprzątanie..."
    sudo paccache -rk 1
    sudo journalctl --vacuum-time=1d
    sync
    echo "\uf0d0 System lśni!"
}

# Turbo / Eco
turbo() { sudo cpupower frequency-set -g performance && echo " TURBO" }
eco()   { sudo cpupower frequency-set -g powersave   && echo " ECO" }
ports() { sudo lsof -i -P -n | grep LISTEN }

# ═══════════════════════════════════════════════════════════════
# SMART EXTRACT
# ═══════════════════════════════════════════════════════════════
ex() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1" ;; *.tar.gz)  tar xzf "$1" ;;
            *.bz2)     bunzip2 "$1"  ;; *.gz)      gunzip "$1"  ;;
            *.rar)     unrar x "$1"  ;; *.tar)     tar xf "$1"  ;;
            *.zip)     unzip "$1"    ;; *.7z)      7z x "$1"    ;;
            *) echo "ex: nieznany format" && return 1 ;;
        esac
        echo -e "\e[32m[\uf07b] Wypakowano. Usunąć archiwum? (y/n)\e[0m"
        read -k 1 res
        [[ "$res" == "y" ]] && rm -v "$1"
    fi
}

# ═══════════════════════════════════════════════════════════════
# WEB SEARCH
# ═══════════════════════════════════════════════════════════════
wiki()   { xdg-open "https://wiki.archlinux.org/index.php?search=$*" &>/dev/null }
google() { xdg-open "https://www.google.com/search?q=$*" &>/dev/null }
github() { xdg-open "https://github.com/search?q=$*" &>/dev/null }

# ═══════════════════════════════════════════════════════════════
# NAWIGACJA (FZF + Zoxide + Yazi)
# ═══════════════════════════════════════════════════════════════
# skoki zoxide
zi() {
    local dir
    dir=$(zoxide query -l 2>/dev/null | fzf --height 50% --layout=reverse --header="\uf07b SysQCLI NAV" --preview='lsd --tree --depth 2 --color=always {} 2>/dev/null')
    [[ -n "$dir" ]] && cd "$dir"
}

# szukaj w plikach  micro
fn() {
    local line
    line=$(rg --column --line-number --no-heading --color=always --smart-case --glob '!.git/*' "$1" 2>/dev/null | \
        fzf --ansi --height 90% --layout=reverse --header=" SysQCLI SEARCH" --preview 'bat --style=numbers --color=always --highlight-line {2} {1} 2>/dev/null')
    [[ -n "$line" ]] && micro "+$(echo "$line" | cut -d: -f2)" "$(echo "$line" | cut -d: -f1)"
}

# przeglądaj pliki
alias fp='fzf --height 90% --layout=reverse --header="\uf15b SysQCLI FILES" \
    --preview "bat --style=numbers --color=always --line-range :500 {} 2>/dev/null || cat {} 2>/dev/null" \
    --bind "enter:execute(micro {})+accept"'

# wybierz i edytuj
fedit() {
    local file
    file=$(find "${1:-.}" -type f 2>/dev/null | fzf --height 50% --layout=reverse --header="[ SysQCLI FILE SELECTOR ]" --preview 'bat --color=always --line-range :500 {} 2>/dev/null || head -50 {}')
    [[ -n "$file" ]] && ${EDITOR:-micro} "$file"
}

# ═══════════════════════════════════════════════════════════════
# ECHO — Lazarus Kernel + Goose (v5.1, 2026-06-20)
# Banner: natywny przez MCP (kernel.banner prompt)
# Session Memory Pipeline: eho (ON), eho0 (OFF)
# ═══════════════════════════════════════════════════════════════

# eho — główny: Session Memory Pipeline ON (domyślnie)
alias eho='SESSION_MEMORY_PIPELINE=1 goose session --name echo --with-builtin developer'

# eho0 — awaryjny: fallback do legacy session_save (bez pipeline)
alias eho0='SESSION_MEMORY_PIPELINE=0 goose session --name echo --with-builtin developer'

# eho1 — pełna ścieżka: lazarus-agent + pidfd lifecycle + MCP
alias eho1='~/projects/lazarus/scripts/deploy.sh && lazarus-agent goose session --name echo --with-builtin developer --with-streamable-http-extension "http://127.0.0.1:9595/mcp"'

# eho-v3 — fallback: deepseek-chat (V3) bez proxy
alias eho-v3='env GOOSE_PROVIDER=custom_deepseek GOOSE_MODEL=deepseek-chat goose session --name backup --with-builtin developer'

# yazi
y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}
