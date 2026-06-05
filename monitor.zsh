#!/usr/bin/env zsh
# ===============================================================
# SysQCLI Config v1.0 — MONITOR (HUD, fkill, qhealth, qtop, qgpu, qtemp)
# ===============================================================

# --- HUD: Live system monitor (paski CPU/RAM + temperatury + MHz) ---
hud() {
    clear
    echo -ne "\e[?25l"
    trap 'echo -ne "\e[?25h"; return' INT

    while true; do
        # Temperatura — sensors + ACPI fallback
        local temp=$(sensors 2>/dev/null | grep -m1 -E 'Package id 0|edge|temp1|CPU|Core 0|composite' | awk '{print ($4=="" ? $2 : $4)}' | tr -d '+')
        if [[ -z "$temp" || "$temp" == "N/A" ]]; then
            for zone in /sys/class/thermal/thermal_zone*/temp; do
                if [[ -f "$zone" ]]; then
                    temp="$(( $(cat "$zone") / 1000 )).0°C"; break
                fi
            done
        fi
        [[ -z "$temp" ]] && temp="N/A"

        # Tryb
        local mode="${SYSCLI_MODE:-full}"
        local mode_col="\e[1;32m"; local emoji="❄️"
        [[ "$SYSCLI_POWER" == "performance" || -n "$SYSCLI_THROTTLED" ]] && { mode_col="\e[1;31m"; emoji="🔥"; }

        # CPU / RAM
        local cpu_perc=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | cut -d. -f1)
        [[ -z "$cpu_perc" || "$cpu_perc" -eq 0 ]] && cpu_perc=1
        local m_data=($(free | awk '/Mem:/ {print $3,$2}'))
        local mem_perc=$(( ${m_data[1]:-0} * 100 / ${m_data[2]:-1} ))
        [[ $mem_perc -eq 0 ]] && mem_perc=1

        # Rysowanie
        echo -ne "\e[H"
        echo -e "  \e[1;35m◢◤ SysQCLI SYSTEM MONITOR ◢◤\e[0m"
        echo -e "  Tryb: $emoji $mode_col$mode\e[0m  |  Temp: \e[1;33m$temp\e[0m  |  Profil: $SYSCLI_PROFILE"
        echo -e "  \e[1;30m──────────────────────────────────────\e[0m"

        # Paski
        local c_f=$(( cpu_perc * 15 / 100 )); [[ $c_f -lt 1 ]] && c_f=1
        local m_f=$(( mem_perc * 15 / 100 )); [[ $m_f -lt 1 ]] && m_f=1
        local c_bar=""; local c_empty=""
        for i in {1..$c_f}; do c_bar+="#"; done
        for i in {1..$((15-c_f))}; do c_empty+="-"; done
        local m_bar=""; local m_empty=""
        for i in {1..$m_f}; do m_bar+="#"; done
        for i in {1..$((15-m_f))}; do m_empty+="-"; done

        printf "  \e[1;34mCPU\e[0m [\e[1;34m%s\e[1;30m%s\e[0m] %3d%%\e[K\n" "$c_bar" "$c_empty" "$cpu_perc"
        printf "  \e[1;36mRAM\e[0m [\e[1;36m%s\e[1;30m%s\e[0m] %3d%%\e[K\n" "$m_bar" "$m_empty" "$mem_perc"
        echo -e "  \e[1;30m──────────────────────────────────────\e[0m"

        # MHz per core
        echo -ne "  \e[1;34mMHz:\e[0m "
        local count=0
        grep "cpu MHz" /proc/cpuinfo | awk '{print $4}' | while read freq; do
            printf "\e[1;37m%4.0f\e[0m " "$freq"
            ((count++))
            (( count % 6 == 0 )) && echo -ne "\n       "
        done

        echo -e "\n  \e[1;30m──────────────────────────────────────\e[0m"
        echo -e "  \e[0;37mCtrl+C aby wyjść\e[0m\e[K"
        sleep 1
    done
}

# --- fkill: Process terminator przez FZF ---
fkill() {
    local pid
    pid=$(ps -u "$USER" -opid,ppid,cmd --forest --no-headers 2>/dev/null | fzf --height 40% --layout=reverse --header="[ SysQCLI PROCESS TERMINATOR ]" | awk '{print $1}')
    if [[ -n "$pid" ]]; then
        echo -ne "\e[1;31mKill PID $pid? (y/n): \e[0m"
        read -k 1 res; echo ""
        [[ "$res" == "y" ]] && kill -9 "$pid" 2>/dev/null && echo "✅ Terminated." || echo "Anulowano."
    fi
}

# --- qhealth: Szybka diagnostyka ---
qhealth() {
    echo -e "\e[1;35m◢◤ SysQCLI HEALTH CHECK ◢◤\e[0m"
    echo -ne "🌡️  CPU: "
    sensors 2>/dev/null | grep -m1 -E 'Package id 0|edge|Core 0' | awk '{print $4}'
    echo -ne "📊 RAM: "
    free -h | awk '/^Mem:/ {print $3 "/" $2 " (" int($3/$2*100) "%)"}'
    echo -ne "💾 Dysk: "
    df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}'
    echo -ne "📦 Aktualizacje: "
    checkupdates 2>/dev/null | wc -l | tr -d '\n'; echo " pakietów"
    echo -ne "💥 Coredumpy (24h): "
    coredumpctl list --since "yesterday" --no-legend 2>/dev/null | wc -l | tr -d '\n'; echo " awarii"
    echo -ne "⏱️  Uptime: "
    uptime -p | sed 's/up //'
    echo -ne "⚡ Governor: "
    cpupower frequency-info 2>/dev/null | grep "governor" | head -1 | awk -F'"' '{print $2}'
}

# --- qtop, qgpu, qtemp: monitoring ---
alias qtop='btop'
alias qtemp='watch -n2 sensors'
qgpu() { nvidia-smi -q -d TEMPERATURE,UTILIZATION,MEMORY 2>/dev/null || echo "❌ nvidia-smi niedostępne"; }
