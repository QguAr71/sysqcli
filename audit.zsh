#!/usr/bin/env zsh
# ===============================================================
# SysQCLI v1.1 — AUDIT & GUARD (Unified preexec + precmd)
# Audyt komend + thermal autopilot + powiadomienia >10s
# v1.1: Security Guard — blokada niebezpiecznych komend
# ===============================================================

AUDIT_LOG="$HOME/.cache/sysqcli_audit.log"
GUARD_LOG="$HOME/.cache/sysqcli_guard.log"
mkdir -p "$(dirname "$AUDIT_LOG")"
zmodload zsh/datetime 2>/dev/null || true

# --- SECURITY GUARD: niebezpieczne wzorce ---
typeset -gA SYSCLI_DANGEROUS=(
  "rm -rf /"               "usuwa cały system"
  "rm -rf ~"               "usuwa cały katalog domowy"
  "sudo rm -rf"            "sudo usuwa wszystko"
  "> /dev/"                "nadpisuje urządzenie blokowe"
  "mkfs"                   "formatuje dysk"
  "dd if="                 "niszczy dane przy złym of="
  ":(){ :|: & };"          "fork bomb — zawiesza system"
  "chmod -R 777 /"         "nadpisuje uprawnienia systemowe"
  "sudo pacman -Rsc"       "usuwa pakiety z zależnościami (kaskada)"
)

# --- PREEXEC: audyt + thermal autopilot + security guard ---
preexec() {
    local cmd="$1"

    # === GUARD: immutable — twarda blokada ===
    if [[ "$SYSCLI_MODE" == "immutable" ]]; then
        if [[ $cmd == *sudo* || $cmd == *pacman*-S* || $cmd == *yay*-S* || \
              $cmd == *rm* || $cmd == *dd* || $cmd == *mkfs* || \
              $cmd == *chattr* ]]; then
            echo -e "\e[1;31m GUARD (immutable): Komenda zablokowana!\e[0m $cmd"
            echo "[$(date '+%F %T')] BLOCKED immutable: $cmd" >> "$GUARD_LOG"
            return 1
        fi
    fi

    # === GUARD: ostrzeżenie + potwierdzenie ===
    for pat in "${(@k)SYSCLI_DANGEROUS}"; do
        if [[ $cmd == *${pat}* ]]; then
            echo -e "\e[1;33m  GUARD: Niebezpieczna komenda!\e[0m"
            echo -e "   ${cmd}"
            echo -e "   Powód: ${SYSCLI_DANGEROUS[$pat]}"
            echo -ne "   Wykonać? [y/N] "
            read -r confirm </dev/tty
            if [[ ! $confirm =~ ^[yY]$ ]]; then
                echo -e "\e[32mAnulowano.\e[0m"
                echo "[$(date '+%F %T')] DENIED: $cmd" >> "$GUARD_LOG"
                return 1
            fi
            echo -e "\e[33mWykonano po potwierdzeniu.\e[0m"
            echo "[$(date '+%F %T')] ALLOWED: $cmd" >> "$GUARD_LOG"
            break
        fi
    done

    # Audyt — loguj każdą komendę z timestampem
    echo "$(date '+%F %T') | $PWD | $cmd" >> "$AUDIT_LOG"

    # Timing
    SYSCLI_CMD_START=$EPOCHSECONDS
    SYSCLI_LAST_CMD=$cmd

    # Thermal autopilot (tylko full mode + laptop)
    [[ "$SYSCLI_MODE" != "full" ]] && return
    [[ "$SYSCLI_PROFILE" != "laptop" ]] && return

    # --- CPU ---
    local temp=$(sensors 2>/dev/null | grep -E 'Package id 0|Core 0|edge|temp1' | grep -v 'N/A' | head -1 | awk '{v=($4==""?$2:$4); gsub(/[^0-9.]/, "", v); print v}')
    [[ -z "$temp" ]] && return

    local t_val=${temp%.*}
    [[ "$t_val" =~ ^[0-9]+$ ]] || return

    # Sync variable with actual governor (catches stale throttle from previous session)
    local actual_gov=$(</sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
    [[ "$actual_gov" == "powersave" && "$SYSCLI_THROTTLED" != "1" ]] && export SYSCLI_THROTTLED=1
    [[ "$actual_gov" == "performance" && "$SYSCLI_THROTTLED" == "1" ]] && export SYSCLI_THROTTLED=0

    # THROTTLE: >78°C
    if [[ $t_val -gt 78 && "$SYSCLI_THROTTLED" != "1" ]]; then
        sudo -n cpupower frequency-set -g powersave >/dev/null 2>&1
        export SYSCLI_THROTTLED=1
        echo -e "\e[31m[ CPU] Throttle ON — ${t_val}°C → powersave\e[0m"
    # RECOVER: <65°C
    elif [[ $t_val -lt 65 && "$SYSCLI_THROTTLED" == "1" ]]; then
        sudo -n cpupower frequency-set -g performance >/dev/null 2>&1
        export SYSCLI_THROTTLED=0
        echo -e "\e[32m[ CPU] Performance restored — ${t_val}°C\e[0m"
    # ALERT: 73-78°C
    elif [[ $t_val -gt 73 ]]; then
        echo -e "\e[33m[ CPU] ${t_val}°C — wysokie obciążenie\e[0m"
    fi

    # --- GPU ---
    if command -v nvidia-smi &>/dev/null; then
        local gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null)
        if [[ "$gpu_temp" =~ ^[0-9]+$ && $gpu_temp -gt 75 ]]; then
            echo -e "\e[31m[ GPU] ${gpu_temp}°C — throttling może wystąpić\e[0m"
        elif [[ "$gpu_temp" =~ ^[0-9]+$ && $gpu_temp -gt 68 ]]; then
            echo -e "\e[33m[ GPU] ${gpu_temp}°C — podwyższona temperatura\e[0m"
        fi
    fi
}

# --- PRECMD: powiadomienia dla długich komend ---
precmd() {
    if (( SYSCLI_CMD_START )); then
        local duration=$(( EPOCHSECONDS - SYSCLI_CMD_START ))
        if (( duration > 10 )); then
            command -v notify-send &>/dev/null && \
                notify-send " SysQCLI: Zadanie zakończone" "Komenda: $SYSCLI_LAST_CMD\nCzas: ${duration}s" --icon=utilities-terminal 2>/dev/null
            echo -e "\e[32m[] Proces trwał ${duration}s — $(echo "$SYSCLI_LAST_CMD" | cut -c1-60)\e[0m"
        fi
        unset SYSCLI_CMD_START
    fi
}

# Alias
alias guard-log='tail -n 30 "$GUARD_LOG" 2>/dev/null || echo "Brak wpisów"'
