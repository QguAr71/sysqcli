#!/usr/bin/env zsh
# ===============================================================
# SysQCLI Config v1.0 — VISUALS (Fastfetch + MOTD + Banner)
# ===============================================================

# --- Fastfetch ---
if [[ "$TERM" == "xterm-kitty" ]]; then
    fastfetch --logo-type kitty 2>/dev/null || fastfetch 2>/dev/null || true
else
    fastfetch 2>/dev/null || true
fi

# --- MOTD ---
sysqcli_motd() {
    [[ -n "$SYSCLI_MOTD_SHOWN" ]] && return
    export SYSCLI_MOTD_SHOWN=1

    echo -e "\n\e[1;35m◢◤ SysQCLI SYSTEM ONLINE ◢◤\e[0m"
    echo -ne "\e[38;2;142;192;124mStatus aktualizacji: \e[1;37m"
    local updates=$(checkupdates 2>/dev/null | wc -l || echo "0")
    echo -e "$updates \e[1;33mpakietów czeka\e[0m"

    echo -ne "\e[38;2;142;192;124mMiejsce na dysku:    \e[1;37m"
    local disk=$(df -h / | awk 'NR==2 {print $5}')
    echo -e "$disk \e[1;32mwykorzystane\e[0m"

    echo -ne "\e[38;2;142;192;124mUptime:             \e[1;37m"
    echo -e "$(uptime -p | sed 's/up //')\e[0m"

    # Coredumps
    local cores=$(coredumpctl list --since "yesterday" --no-legend 2>/dev/null | wc -l)
    [[ $cores -gt 0 ]] && echo -e "\e[33m $cores awarii od wczoraj — wpisz 'fix'\e[0m"

    # RAM warning at start
    local mem_used=$(free | awk '/^Mem:/ {print $3}')
    local mem_total=$(free | awk '/^Mem:/ {print $2}')
    if [[ -n "$mem_used" && -n "$mem_total" ]]; then
        local usage=$(( mem_used * 100 / mem_total ))
        [[ $usage -gt 90 ]] && echo -e "\e[31m RAM: ${usage}% — rozważ zamknięcie aplikacji\e[0m"
    fi

    echo ""
}

sysqcli_motd
