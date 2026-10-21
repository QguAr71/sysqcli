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
# SYSQ — Lazarus Kernel + Goose (v1.15, 2026-06-27)
# sysq  = full pipeline: lazarus-agent → pidfd → MCP → Citadel/Vault
# dev   = sandbox (DEV-ONLY): lazarus-agent + osobny Wing
# goose = fallback: goły goose, działa zawsze gdy lazarusd padnie
# ═══════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════
# ZERO-TRACE FAZA 3 — Context Gate: headroom lossless jako DOMYŚLNA ścieżka
#
# goose_via_headroom <name> [extra env] — uruchamia goose przez Headroom
# (:8787) → lazarus-network (:9998), w trybie:
#   --mode cache        = freeze prior turns (prefix-cache DeepSeek)
#   --lossless          = format-native lossless (bez markerów CCR/retrieve)
#   --protect-tool-results Bash,Read = nigdy nie kompresuj tych tool results
# Fallback (I-18): gdy headroom nie wstaje → goły goose prosto na :9998.
# NIGDY nie blokuje startu — headroom to optymalizacja, nie wymóg.
# ═══════════════════════════════════════════════════════════════
goose_via_headroom() {
    local name="$1"; shift
    local hr_port="${HEADROOM_PORT:-8787}"
    local upstream="http://127.0.0.1:9998/v1"

    # 1) Headroom ma sens tylko gdy lazarus-network (:9998) żyje.
    if ! curl -sf "http://127.0.0.1:9998/health" >/dev/null 2>&1; then
        echo -e "\e[33;1m⚠ lazarus-network (9998) nie działa — fallback na goły goose.\e[0m"
        lazarus-agent goose session --name "$name" --with-builtin developer,autovisualiser,computercontroller,memory "$@"
        return $?
    fi

    # 2) Podnieś Headroom jeśli nie żyje (lossless + protect-tool-results).
    if ! curl -sf "http://127.0.0.1:${hr_port}/health" >/dev/null 2>&1; then
        mkdir -p ~/.cache/headroom
        ( HEADROOM_BEACON=off DO_NOT_TRACK=1 \
            setsid headroom proxy --port "$hr_port" \
            --mode cache --lossless --protect-tool-results Bash,Read \
            --openai-api-url "$upstream" \
            >~/.cache/headroom/proxy.log 2>&1 & )
        for _ in {1..40}; do
            curl -sf "http://127.0.0.1:${hr_port}/health" >/dev/null 2>&1 && break
            sleep 0.2
        done
    fi

    # 3) Headroom wstał → goose przez headroom; inaczej fallback na goły goose (I-18).
    if curl -sf "http://127.0.0.1:${hr_port}/health" >/dev/null 2>&1; then
        OPENAI_BASE_URL="http://127.0.0.1:${hr_port}/v1" \
        OPENAI_TARGET_API_URL="$upstream" \
        lazarus-agent goose session --name "$name" --with-builtin developer,autovisualiser,computercontroller,memory "$@"
    else
        echo -e "\e[33;1m⚠ Headroom proxy nie wystartował — fallback na goły goose (:9998). log: ~/.cache/headroom/proxy.log\e[0m"
        lazarus-agent goose session --name "$name" --with-builtin developer,autovisualiser,computercontroller,memory "$@"
    fi
}

# sysq — pełna ścieżka (lazarus-agent + pidfd lifecycle + MCP)
# Automatycznie aktualizuje port MCP w goose config przed startem.
sysq() {
    local port=$(cat ~/.cache/lazarus/mcp_port 2>/dev/null | tr -d '\n')
    port="${port:-9595}"
    sed -i "s|uri: http://localhost:[0-9]\+/mcp|uri: http://localhost:${port}/mcp|" ~/.config/goose/config.yaml

    # ══ PEAK/OFF-PEAK ALERT ══
    # Oficjalne okna szczytu DeepSeek: 01:00-04:00 UTC i 06:00-10:00 UTC.
    # Czerwono = PEAK (drożej, rozważ Flash). Zielono = OFF-PEAK.
    local now_utc_min now_hh now_mm peak=""
    now_utc_min=$(( $(date -u +%H) * 60 + $(date -u +%M) ))
    now_hh=$(date -u +%H); now_mm=$(date -u +%M)
    if (( (now_utc_min >= 60 && now_utc_min < 240) || (now_utc_min >= 360 && now_utc_min < 600) )); then
        peak=1
    fi
    if [[ -n "$peak" ]]; then
        echo -e "\e[31;1m⚠ PEAK $now_hh:$now_mm UTC — DeepSeek taryfa szczytowa (01-04 / 06-10 UTC)\e[0m"
        echo -en "\a"
    else
        echo -e "\e[32;1m✓ OFF-PEAK — $now_hh:$now_mm UTC, taryfa normalna\e[0m"
    fi

    goose_via_headroom "sysq"
}

# dev — sandbox (DEV-ONLY): osobny lazarusd :9596 + osobny config ~/.config/goose-sandbox
alias dev='GOOSE_PROVIDER=deepseek-v4-sandbox GOOSE_MODEL=deepseek-v4-pro GOOSE_CONFIG_DIR=$HOME/.config/goose-sandbox LAZARUS_SUPERWING=dev LAZARUS_WING=default GOOSE_CLI_MIN_PRIORITY=0.9 lazarus-agent goose session --name dev --with-builtin developer,autovisualiser,computercontroller,memory'

# eho — pełna ścieżka jak sysq, ale provider deepseek-v4-proxy (deepseek-v4-pro)
eho() {
    local port=$(cat ~/.cache/lazarus/mcp_port 2>/dev/null | tr -d '\n')
    port="${port:-9595}"
    sed -i "s|uri: http://localhost:[0-9]\+/mcp|uri: http://localhost:${port}/mcp|" ~/.config/goose/config.yaml

    # ══ PEAK/OFF-PEAK ALERT ══
    local now_utc_min now_hh now_mm peak=""
    now_utc_min=$(( $(date -u +%H) * 60 + $(date -u +%M) ))
    now_hh=$(date -u +%H); now_mm=$(date -u +%M)
    if (( (now_utc_min >= 60 && now_utc_min < 240) || (now_utc_min >= 360 && now_utc_min < 600) )); then
        peak=1
    fi
    if [[ -n "$peak" ]]; then
        echo -e "\e[31;1m⚠ PEAK $now_hh:$now_mm UTC — DeepSeek taryfa szczytowa (01-04 / 06-10 UTC)\e[0m"
        echo -en "\a"
    else
        echo -e "\e[32;1m✓ OFF-PEAK — $now_hh:$now_mm UTC, taryfa normalna\e[0m"
    fi

    GOOSE_PROVIDER=deepseek-v4-proxy GOOSE_MODEL=deepseek-v4-pro goose_via_headroom "eho"
}

# eho1 — awaryjny: cienki wrapper (lazarus-session, sam auto-handoff) + v4-pro.
# Działa gdy lazarusd/lazarus-agent padnie — nie wymaga pidfd ani MCP bridge.
alias eho1='GOOSE_PROVIDER=deepseek-v4-proxy GOOSE_MODEL=deepseek-v4-pro ~/bin/lazarus-session'

# gpt — provider vision (gpt-5.4, OpenAI). Test warstwy LLM Scheduler (task 7f7a72fafd0817b8).
# Klucz: OPENAI_API_KEY w ~/.zshrc. Używaj do zadań z obrazkami (efekt blasku itp.).
# Analogicznie do eho, ale bez peak-alert (OpenAI nie ma taryfy szczytowej DeepSeek).
gpt() {
    local port=$(cat ~/.cache/lazarus/mcp_port 2>/dev/null | tr -d '\n')
    port="${port:-9595}"
    sed -i "s|uri: http://localhost:[0-9]\+/mcp|uri: http://localhost:${port}/mcp|" ~/.config/goose/config.yaml

    GOOSE_PROVIDER=gpt GOOSE_MODEL=gpt-5.4 lazarus-agent goose session --name gpt --with-builtin developer,autovisualiser,computercontroller,memory
}

# gs — czysty goose (cienki wrapper auto-handoff, domyślny active_provider z config.yaml)
alias gs='~/bin/lazarus-session'

# ═══════════════════════════════════════════════════════════════
# HEADROOM — prefix-cache + lossless kompresja tool results (proxy przed lazarus-network)
# Ścieżka: goose → headroom (:8787/v1) → lazarus-network (:9998/v1) → DeepSeek
# Tryb (ZERO-TRACE Faza 3): --mode cache (freeze prior turns, prefix-cache) +
# --lossless (format-native, bez markerów CCR/retrieve) +
# --protect-tool-results Bash,Read (nigdy nie kompresuj tych tool results).
# Fallback I-18: headroom nie wstaje → goły goose :9998. NIGDY nie blokuje startu.
# ═══════════════════════════════════════════════════════════════
goose-hr() {
    # ZERO-TRACE Faza 3: goose-hr = jawne wywołanie headroom lossless (już
    # domyślne dla sysq/eho). Zachowanie providera jak dotąd (v4-proxy).
    GOOSE_PROVIDER=deepseek-v4-proxy GOOSE_MODEL=deepseek-v4-pro goose_via_headroom "sysq-hr"
}

# ═══════════════════════════════════════════════════════════════
# OMNIROUTE — darmowe tokeny (osobny gateway :20128, niezależny od Lazarus)
# ═══════════════════════════════════════════════════════════════
goose-free() {
    local omni_bin="$HOME/.local/share/omniroute/node_modules/omniroute/bin/omniroute.mjs"
    local omni_port="${OMNIROUTE_PORT:-20128}"

    if [[ ! -f "$omni_bin" ]]; then
        echo -e "\e[31;1m⚠ OmniRoute nie zainstalowany (brak: $omni_bin)\e[0m"
        return 1
    fi

    # 1) Upewnij się, że OmniRoute gateway działa.
    if ! curl -sf "http://localhost:${omni_port}/v1/models" >/dev/null 2>&1; then
        echo -e "\e[33;1m⏳ Startuję OmniRoute gateway (port ${omni_port})…\e[0m"
        ( OMNIROUTE_SERVER_HOST=127.0.0.1 setsid node "$omni_bin" serve --port "$omni_port" --no-open --daemon \
            >~/.cache/omniroute.log 2>&1 & )
        for _ in {1..40}; do
            curl -sf "http://localhost:${omni_port}/v1/models" >/dev/null 2>&1 && break
            sleep 0.5
        done
        if ! curl -sf "http://localhost:${omni_port}/v1/models" >/dev/null 2>&1; then
            echo -e "\e[31;1m⚠ OmniRoute nie wystartował — log: ~/.cache/omniroute.log\e[0m"
            return 1
        fi
        echo -e "\e[32;1m✓ OmniRoute gateway na :${omni_port}\e[0m"
    fi

    # 2) Uruchom goose przez OmniRoute (OpenAI-compatible endpoint).
    OPENAI_BASE_URL="http://localhost:${omni_port}/v1" \
      OPENAI_API_KEY="omniroute-free" \
      GOOSE_PROVIDER=deepseek-v4-proxy GOOSE_MODEL=auto \
      lazarus-agent goose session --name sysq-free --with-builtin developer,autovisualiser,computercontroller,memory
}

# yazi
y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}
