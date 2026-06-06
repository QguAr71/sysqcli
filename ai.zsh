#!/usr/bin/env zsh
# ===============================================================
# SysQCLI Config v1.0 — AI (Ollama + Cache + Fix + Summary)
# ===============================================================

AI_CACHE="$HOME/.cache/sysqcli_ai"
AI_TTL=$((60*60*24))  # 24 godziny
mkdir -p "$AI_CACHE"

# --- AI: pomocnicze ---
_ai_ready() {
    command -v ollama &>/dev/null || { echo " Ollama nie jest zainstalowana. Wpisz 'qinstall'."; return 1; }
    return 0
}

# --- Cache ---
_ai_cache_valid() {
    [[ ! -f "$1" ]] && return 1
    local age=$(( $(date +%s) - $(stat -c %Y "$1") ))
    (( age < AI_TTL ))
}

_ai_cache_purge() {
    find "$AI_CACHE" -type f -mtime +1 -delete 2>/dev/null
}

# --- AI: główna funkcja ---
ai() {
    _ai_ready || return 1

    # Profile Ollama (dopasowane do 6GB VRAM, 32GB RAM)
    local PROFILE="mechanik"                     # deepseek-coder-v2:16b Q4_0, 8.9GB, 23.8 t/s
    case "$1" in
        -f) PROFILE="mini"; shift ;;               # qwen2.5:7b Q4_K_M, 4.7GB full GPU, 39 t/s

        -m) PROFILE="mechanik"; shift ;;           # jawnie mechanik
    esac

    local q="$*"
    [[ -z "$q" ]] && { echo "ai: podaj pytanie."; return 1; }

    # Cache key
    local h=$(echo "$PROFILE$q" | sha256sum | cut -d' ' -f1)
    local f="$AI_CACHE/$h.md"

    _ai_cache_valid "$f" && { cat "$f"; return; }

    echo -e "\e[34m[ AI: $PROFILE]\e[0m"
    ollama run "$PROFILE" "INSTRUKCJA: Odpowiadaj wyłącznie po polsku. $q" | tee "$f"
}

# --- Fix: AI diagnoza (journalctl + coredumpctl + failed services) ---
fix() {
    _ai_ready || return 1
    echo -e "\e[33m[ SysQCLI DIAG] Zbieram dane...\e[0m"

    local diag=""
    local sep="========================================"

    # 1. Failed systemd user services
    local failed=$(systemctl --user --failed --no-legend 2>/dev/null | head -10)
    [[ -n "$failed" ]] && diag+="=== USŁUGI USER (failed) ===\n${failed}\n\n"

    # 2. Unikalne błędy z journalctl (bez stack trace, bez szumu)
    local jrnl=$(journalctl -p 3 -xb -n 30 -o cat --no-pager 2>/dev/null \
        | grep -vE '^\s*(#|Stack trace|Available|ELF|$)' \
        | grep -vE 'dumped core|░░|\.so\.|pthread_kill|raise|abort|PyEval|Py_Bytes|Py_Run|__libc_start' \
        | sort -u)
    [[ -n "$jrnl" ]] && diag+="=== UNIKALNE BŁĘDY JOURNALCTL ===\n${jrnl}\n\n"

    # 3. Coredumpctl — statystyka (nie pełna lista)
    local total_cores=$(coredumpctl list --since yesterday --no-legend 2>/dev/null | wc -l)
    local core_summary=$(coredumpctl list --since yesterday --no-legend 2>/dev/null \
        | awk '{for(i=1;i<=NF;i++) if($i ~ /^\//) print $i}' | sort | uniq -c | sort -rn | head -10)
    [[ "$total_cores" -gt 0 ]] && diag+="=== COREDUMPY (24h: ${total_cores} razem) ===\n${core_summary}\n\n"

    [[ -z "$diag" ]] && { echo " System czysty — brak błędów."; return 0; }

    local prompt="Jesteś diagnostą systemowym Arch Linux. Odpowiadaj tylko po polsku, zwięźle — maksymalnie 5 zdań.
Poniżej REALNE dane diagnostyczne z systemu użytkownika (NIE hipotetyczne):
${diag}
Twoje zadanie:
1. Wskaż ROOT CAUSE — nazwę usługi/procesu który generuje najwięcej awarii.
2. Podaj KONKRETNĄ komendę naprawy (np. systemctl disable, pacman -S, edycja pliku).
3. NIE pisz ogólnych porad typu 'sprawdź logi' czy 'zaktualizuj system'.
BADŹ KONKRETNY."

    echo -e "\e[34m[ AI: mechanik]\e[0m"
    ollama run "mechanik" "$prompt"
}

# --- Summary: AI podsumowanie dnia ---
summary() {
    _ai_ready || return 1
    echo -e "\e[34m[ AI analizuje Twój dzień...]\e[0m"
    local hist=$(atuin history list --limit 50 2>/dev/null || fc -ln -50)
    echo -e "MOJA HISTORIA:\n$hist" | ai "Podsumuj krótko co robiłem i zasugeruj jeden przydatny alias."
}

# --- Command not found handler ---
command_not_found_handler() {
    echo -e "\e[31m[] Polecenie '$1' nie istnieje.\e[0m"
    _ai_ready && ai "Użytkownik wpisał '$1' które nie istnieje. Podaj krótką sugestię naprawy." 2>/dev/null
    return 127
}

# --- Aliasy AI ---
alias sc='ai'          # DeepSeek Coder (domyślny)
alias si='ai -f'       # Phi3 mini (szybki)
alias sii='ai'         # DeepSeek Coder


# --- Purge cache przy starcie ---
_ai_cache_purge
