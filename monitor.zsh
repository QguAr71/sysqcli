#!/usr/bin/env zsh
# ===============================================================
# SysQCLI v1.1 — MONITOR (HUD, fkill, qhealth, qtop, qgpu, qtemp)
# v1.1: qhealth — LANG=C free (locale PL) + cpupower governor awk fix
# ===============================================================

# --- fkill: Process terminator przez FZF ---
fkill() {
    local pid
    pid=$(ps -u "$USER" -opid,ppid,cmd --forest --no-headers 2>/dev/null | fzf --height 40% --layout=reverse --header="[ SysQCLI PROCESS TERMINATOR ]" | awk '{print $1}')
    if [[ -n "$pid" ]]; then
        echo -ne "\e[1;31mKill PID $pid? (y/n): \e[0m"
        read -k 1 res; echo ""
        [[ "$res" == "y" ]] && kill -9 "$pid" 2>/dev/null && echo " Terminated." || echo "Anulowano."
    fi
}

# --- qhealth: Szybka diagnostyka ---
qhealth() {
    echo -e "\e[1;35m═══ SysQCLI HEALTH CHECK ═══\e[0m"
    echo -ne "  CPU: "
    sensors 2>/dev/null | grep -E 'Package id 0|edge|Core 0' | grep -v 'N/A' | head -1 | awk '{print $4}'
    echo -ne " RAM: "
    LANG=C free -h | awk '/^Mem:/ {print $3 "/" $2 " (" int($3/$2*100) "%)"}'
    echo -ne " Dysk: "
    df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}'
    echo -ne " Aktualizacje: "
    checkupdates 2>/dev/null | wc -l | tr -d '\n'; echo " pakietów"
    echo -ne "\uf188 Coredumpy (24h): "
    coredumpctl list --since "yesterday" --no-legend 2>/dev/null | wc -l | tr -d '\n'; echo " awarii"
    echo -ne "  Uptime: "
    uptime -p | sed 's/up //'
    echo -ne " Governor: "
    cpupower frequency-info 2>/dev/null | awk -F'"' '/The governor/ {print $2; exit}'
}

# --- qtop, qgpu, qtemp: monitoring ---
alias qtop='btop'
alias qtemp='watch -n2 sensors'
qgpu() { nvidia-smi -q -d TEMPERATURE,UTILIZATION,MEMORY 2>/dev/null || echo " nvidia-smi niedostępne"; }
