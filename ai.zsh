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

# --- Modular Collectors (v0.2) ---

_collect_systemd_failed() {
    systemctl --user --failed --no-legend 2>/dev/null | awk '{print "FAILED:"$2}'
    systemctl --failed --no-legend 2>/dev/null | awk '{print "FAILED:"$2}'
}

_collect_coredumps() {
    coredumpctl list --since yesterday --no-legend 2>/dev/null \
        | awk '{for(i=1;i<=NF;i++) if($i ~ /^\//) {print "CORE:"$i; break}}'
    coredumpctl list --since yesterday --no-legend 2>/dev/null \
        | awk '{print $6}' | sort -u | while read s; do echo "SIGNAL:$s"; done
}

_collect_journal_errors() {
    journalctl -p 3 -xb -n 30 -o cat --no-pager 2>/dev/null \
        | grep -vE '^\s*(#|Stack trace|Available|ELF|$)' \
        | grep -vE 'dumped core|░░|\.so\.|pthread_kill|raise|abort|PyEval|Py_Bytes|Py_Run|__libc_start' \
        | sort -u | tr '\n' '|'
}

_collect_session_info() {
    echo "CONTEXT:kernel=$(uname -r)"
    echo "CONTEXT:desktop=${XDG_CURRENT_DESKTOP:-unknown}"
    echo "CONTEXT:session=${XDG_SESSION_TYPE:-unknown}"
    echo "CONTEXT:host=$(hostname)"
    echo "CONTEXT:uptime=$(uptime -p | sed 's/up //')"
    command -v nvidia-smi &>/dev/null && echo "CONTEXT:gpu=nvidia" || echo "CONTEXT:gpu=none"
}

# --- Fix: Diagnostyka deterministyczna + certyfikowane wzorce (v0.2) ---
fix() {
    local mode="${1:-full}"
    local dry_run=0

    case "$mode" in
        --dry-run) dry_run=1; mode="full" ;;
        --explain) _fix_explain "$2"; return ;;
        --report)  _fix_report; return ;;
    esac

    echo -e "\e[33m[ SysQCLI DIAG] Zbieram dane...\e[0m"
    [[ $dry_run -eq 1 ]] && echo -e "\e[36m[DRY-RUN] Tryb symulacji — żadne zmiany nie zostaną wykonane.\e[0m"

    # 1. Collect (modular)
    local tmpfile="/tmp/sysqcli_diag_$$"
    _collect_systemd_failed > "$tmpfile"
    _collect_coredumps >> "$tmpfile"
    _collect_session_info >> "$tmpfile"
    echo "ERRORS:$(_collect_journal_errors)" >> "$tmpfile"

    # 2. Match
    local result=$(python3 ~/.config/sysqcli/patterns/matcher.py < "$tmpfile" 2>/dev/null)
    rm -f "$tmpfile"

    if [[ -z "$result" ]]; then
        echo -e "\e[1;31m✗ Błąd: nie można uruchomić matcher.py\e[0m"
        return 1
    fi

    # 3. Display
    if [[ "$result" == "NO_MATCH" ]]; then
        _fix_no_match
    else
        _fix_show_match "$result" "$dry_run"
    fi
}

# --- Helper: wyświetl dopasowane rozwiązanie ---
_fix_show_match() {
    local data="$1"
    local dry_run="${2:-0}"
    local id=$(echo "$data" | grep '^ID:' | cut -d: -f2-)
    local name=$(echo "$data" | grep '^NAME:' | cut -d: -f2-)
    local conf=$(echo "$data" | grep '^CONFIDENCE:' | cut -d: -f2-)
    local risk=$(echo "$data" | grep '^RISK:' | cut -d: -f2-)
    local expl=$(echo "$data" | grep '^EXPLANATION:' | cut -d: -f2-)
    local impact=$(echo "$data" | grep '^IMPACT:' | cut -d: -f2-)
    local action=$(echo "$data" | grep '^ACTION:' | cut -d: -f2-)
    local rollback=$(echo "$data" | grep '^ROLLBACK:' | cut -d: -f2-)
    local alt=$(echo "$data" | grep '^ALT:' | cut -d: -f2-)
    local score=$(echo "$data" | grep '^SCORE:' | cut -d: -f2-)

    # Confidence badge
    local badge=""
    case "$conf" in
        certified)  badge="\e[32m✓ ROZWIĄZANIE CERTYFIKOWANE\e[0m" ;;
        community)  badge="\e[33m⚠ SUGESTIA SPOŁECZNOŚCI\e[0m" ;;
        *)          badge="\e[31m⚠ NIECERTYFIKOWANE\e[0m" ;;
    esac

    # Risk badge
    local rbadge=""
    case "$risk" in
        low)    rbadge="\e[32mniskie\e[0m" ;;
        medium) rbadge="\e[33mśrednie\e[0m" ;;
        high)   rbadge="\e[31mwysokie\e[0m" ;;
        none)   rbadge="brak" ;;
    esac

    echo -e "\n$badge"
    [[ -n "$score" ]] && echo -e "\e[90m  Score: $score\e[0m"
    echo -e "\e[1;36m═══════ $name ═══════\e[0m"
    echo -e "\e[1;33mPrzyczyna:\e[0m $expl"
    [[ -n "$impact" ]] && echo -e "\e[1;33mSkutki:\e[0m   $impact"
    echo ""
    echo -e "\e[1;32mRozwiązanie:\e[0m $action"
    [[ -n "$alt" ]] && echo -e "\e[1;34mAlternatywa:\e[0m $alt"
    echo ""
    echo -e "  Ryzyko:     $rbadge"
    echo -e "  Źródło:     $conf"
    [[ -n "$rollback" ]] && echo -e "  Rollback:   $rollback"
    echo ""

    # Dry-run — tylko symulacja
    if [[ $dry_run -eq 1 ]]; then
        echo -e "\e[36m[SYMULACJA] Wykonałbym: $action\e[0m"
        [[ -n "$rollback" ]] && echo -e "\e[36m[SYMULACJA] Rollback:     $rollback\e[0m"
        echo -e "\e[36m[SYMULACJA] Status: brak zmian w systemie.\e[0m"
        return
    fi

    # Action prompt
    if [[ "$conf" == "ai_suggestion" ]]; then
        echo -e "\e[31m⚠ Rozwiązanie niecertyfikowane — SysQCLI NIE wykona go automatycznie.\e[0m"
        echo -e "Masz opcje: [R]aport  [D]eleguj  [A]nuluj"
        read "choice?► "
    else
        echo -ne "Wykonać? \e[1m[T/n]\e[0m "
        read -r confirm
        if [[ "$confirm" == "T" || "$confirm" == "t" || -z "$confirm" ]]; then
            echo -e "\e[33mWykonuję: $action\e[0m"
            eval "$action"
            local ret=$?
            if [[ $ret -eq 0 ]]; then
                echo -e "\e[32m✓ Wykonano pomyślnie.\e[0m"
            else
                echo -e "\e[31m✗ Błąd wykonania (kod: $ret)\e[0m"
                [[ -n "$rollback" ]] && echo -e "\e[33mRollback: $rollback\e[0m"
            fi
        else
            echo "Anulowano."
        fi
    fi
}

# --- Helper: brak dopasowania ---
_fix_no_match() {
    echo -e "\e[33m\n⚠ Problem nierozpoznany\e[0m"
    echo -e "SysQCLI nie posiada certyfikowanej procedury dla tego typu błędu."
    echo ""
    echo -e "Dostępne opcje:"
    echo -e "  \e[1m[R]\e[0maport   — zapisz raport diagnostyczny do pliku"
    echo -e "  \e[1m[D]\e[0meleguj — przekaż do Goose (jeśli dostępny)"
    echo -e "  \e[1m[S]\e[0mpołeczność — link do zgłoszeń"
    echo -e "  \e[1m[A]\e[0mnuluj"
    echo ""
    read "choice?► "

    case "$choice" in
        [Rr])
            _fix_report
            ;;
        [Dd])
            if command -v goose &>/dev/null; then
                echo "Deleguję do Goose..."
                goose "Diagnozuj problemy systemowe: $(journalctl -p 3 -xb -n 30 -o cat --no-pager 2>/dev/null | grep -vE 'Stack trace|\.so\.' | sort -u | head -10 | tr '\n' ' ')"
            else
                echo "Goose nie jest dostępny."
            fi
            ;;
        [Ss])
            echo "Zgłoś na: https://github.com/QguAr71/sysqcli/issues"
            ;;
        *)
            echo "Anulowano."
            ;;
    esac
}

# --- Helper: raport diagnostyczny ---
_fix_report() {
    local report="$HOME/sysqcli_report_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "═══════ SysQCLI Diagnostic Report ═══════"
        echo "Data:      $(date '+%F %T')"
        echo "Host:      $(hostname)"
        echo "Kernel:    $(uname -r)"
        echo "DE:        ${XDG_CURRENT_DESKTOP:-unknown}"
        echo "Session:   ${XDG_SESSION_TYPE:-unknown}"
        echo "Uptime:    $(uptime -p | sed 's/up //')"
        command -v nvidia-smi &>/dev/null && echo "GPU:       nvidia ($(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null))"
        echo ""
        echo "=== FAILED SERVICES ==="
        systemctl --user --failed --no-legend 2>/dev/null
        systemctl --failed --no-legend 2>/dev/null
        echo ""
        echo "=== COREDUMPS (24h) ==="
        echo "Total: $(coredumpctl list --since yesterday --no-legend 2>/dev/null | wc -l)"
        coredumpctl list --since yesterday --no-legend 2>/dev/null \
            | awk '{for(i=1;i<=NF;i++) if($i ~ /^\//) print $i}' | sort | uniq -c | sort -rn | head -10
        echo ""
        echo "=== JOURNALCTL ERRORS (unique) ==="
        journalctl -p 3 -xb -n 30 -o cat --no-pager 2>/dev/null \
            | grep -vE '^\s*(#|Stack trace|Available|ELF|$)' \
            | grep -vE '\.so\.|pthread_kill|raise|abort|PyEval|Py_Bytes|Py_Run|__libc_start' \
            | sort -u
    } > "$report"
    echo -e "\e[32mRaport zapisany: $report\e[0m"
}

# --- Helper: wyjaśnienie konkretnego błędu ---
_fix_explain() {
    local query="$*"
    [[ -z "$query" ]] && { echo "fix --explain <nazwa usługi lub błędu>"; return 1; }
    echo -e "\e[34m[ AI: mechanik] Wyjaśniam: $query\e[0m"
    _ai_ready && ollama run "mechanik" "Wyjaśnij po polsku, zwięźle (max 3 zdania), co oznacza ten błąd systemowy: $query"
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
