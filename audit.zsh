#!/usr/bin/env zsh
# ===============================================================
# SysQCLI Config v1.0 — AUDIT (Unified preexec + precmd)
# Audyt ksysqclid + thermal autopilot + powiadomienia >10s
# ===============================================================

AUDIT_LOG="$HOME/.cache/sysqcli_audit.log"
mkdir -p "$(dirname "$AUDIT_LOG")"
zmodload zsh/datetime 2>/dev/null || true

# --- PREEXEC: audyt + thermal autopilot ---
preexec() {
    # Audyt — loguj każdą ksysqclidę z timestampem
    echo "$(date '+%F %T') | $PWD | $1" >> "$AUDIT_LOG"

    # Timing
    SYSCLI_CMD_START=$EPOCHSECONDS
    SYSCLI_LAST_CMD=$1

    # Thermal autopilot (tylko full mode + laptop)
    [[ "$SYSCLI_MODE" != "full" ]] && return
    [[ "$SYSCLI_PROFILE" != "laptop" ]] && return

    local temp=$(sensors 2>/dev/null | grep -m1 -E 'Package id 0|Core 0|edge|temp1' | awk '{print ($4=="" ? $2 : $4)}' | tr -d '+°C')
    [[ -z "$temp" ]] && return

    local t_val=${temp%.*}
    # THROTTLE: >83°C
    if [[ $t_val -gt 83 && "$SYSCLI_THROTTLED" != "1" ]]; then
        sudo -n cpupower frequency-set -g powersave >/dev/null 2>&1
        export SYSCLI_THROTTLED=1
        echo -e "\e[31m[🔥 THERMAL] Throttle ON — ${t_val}°C → powersave\e[0m"
    # RECOVER: <65°C
    elif [[ $t_val -lt 65 && "$SYSCLI_THROTTLED" == "1" ]]; then
        sudo -n cpupower frequency-set -g performance >/dev/null 2>&1
        export SYSCLI_THROTTLED=0
        echo -e "\e[32m[❄️ THERMAL] Performance restored — ${t_val}°C\e[0m"
    # ALERT: 78-83°C
    elif [[ $t_val -gt 78 ]]; then
        echo -e "\e[33m[⚠️ THERMAL] ${t_val}°C — wysokie obciążenie\e[0m"
    fi
}

# --- PRECMD: powiadomienia dla długich ksysqclid ---
precmd() {
    if (( SYSCLI_CMD_START )); then
        local duration=$(( EPOCHSECONDS - SYSCLI_CMD_START ))
        if (( duration > 10 )); then
            command -v notify-send &>/dev/null && \
                notify-send "🚀 SysQCLI: Zadanie zakończone" "Ksysqclida: $SYSCLI_LAST_CMD\nCzas: ${duration}s" --icon=utilities-terminal 2>/dev/null
            echo -e "\e[32m[🔔] Proces trwał ${duration}s — $(echo "$SYSCLI_LAST_CMD" | cut -c1-60)\e[0m"
        fi
        unset SYSCLI_CMD_START
    fi
}
