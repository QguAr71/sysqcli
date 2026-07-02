#!/usr/bin/env zsh
# ===============================================================
# SysQCLI v1.4 — AI (Ollama + fix() Diagnostic Engine + Goose Bridge)
# v1.1: dodano fix(), v1.2: stale throttle, v1.3: thermal autopilot
# v1.4: YAML patterns + matcher + --dry-run/--friendly/--report/--explain

# Guard: załaduj .sysqclirc przed definicjami funkcji
# (eliminuje race condition AI startu przed zmiennymi środowiskowymi)
[[ -f "$HOME/.sysqclirc" ]] && source "$HOME/.sysqclirc"
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

# Pacman lockfile check
_collect_pacman_lock() {
    [[ -f "/var/lib/pacman/db.lck" ]] && echo "ERRORS:pacman: unable to lock database (/var/lib/pacman/db.lck exists)"
}
}

# --- Fix: Diagnostyka deterministyczna + certyfikowane wzorce (v0.3) ---
fix() {
    local mode="${1:-full}"
    local dry_run=0
    local friendly=0

    case "$mode" in
        --dry-run) dry_run=1; mode="full" ;;
        --friendly) friendly=1; mode="full" ;;
        --explain) _fix_explain "$2"; return ;;
        --report)  _fix_report; return ;;
    esac

    echo -e "\e[33m[ SysQCLI DIAG] Zbieram dane...\e[0m"
    [[ $dry_run -eq 1 ]] && echo -e "\e[36m[DRY-RUN] Tryb symulacji — żadne zmiany nie zostaną wykonane.\e[0m"
    [[ $friendly -eq 1 ]] && echo -e "\e[35m[ Przyjazny] AI przetłumaczy diagnozę na naturalny język...\e[0m"

    # 1. Collect (modular)
    local tmpfile="/tmp/sysqcli_diag_$$"
    _collect_systemd_failed > "$tmpfile"
    _collect_coredumps >> "$tmpfile"
    _collect_session_info >> "$tmpfile"
    _collect_pacman_lock >> "$tmpfile"
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
    elif [[ $friendly -eq 1 ]]; then
        _fix_show_match_friendly "$result" "$dry_run"
    else
        _fix_show_match "$result" "$dry_run"
    fi
}

# --- Helper: przyjazne wyjaśnienie przez 16B translator (v0.3) ---
_fix_show_match_friendly() {
    local data="$1"
    local dry_run="${2:-0}"
    local name=$(echo "$data" | grep '^NAME:' | cut -d: -f2-)
    local expl=$(echo "$data" | grep '^EXPLANATION:' | cut -d: -f2-)
    local impact=$(echo "$data" | grep '^IMPACT:' | cut -d: -f2-)
    local action=$(echo "$data" | grep '^ACTION:' | cut -d: -f2-)
    local risk=$(echo "$data" | grep '^RISK:' | cut -d: -f2-)
    local rollback=$(echo "$data" | grep '^ROLLBACK:' | cut -d: -f2-)
    local conf=$(echo "$data" | grep '^CONFIDENCE:' | cut -d: -f2-)
    local alt=$(echo "$data" | grep '^ALT:' | cut -d: -f2-)
    local score=$(echo "$data" | grep '^SCORE:' | cut -d: -f2-)
    local kernel=$(echo "$data" | grep '^CONTEXT_KERNEL:' | cut -d: -f2-)
    local desktop=$(echo "$data" | grep '^CONTEXT_DESKTOP:' | cut -d: -f2-)
    local session=$(echo "$data" | grep '^CONTEXT_SESSION:' | cut -d: -f2-)

    if ! _ai_ready 2>/dev/null; then
        echo -e "\e[33m⚠ Ollama offline — pokazuję wersję techniczną.\e[0m"
        _fix_show_match "$data" "$dry_run"
        return
    fi

    echo -e "\n\e[35m[ AI: mechanik] Tłumaczę diagnozę...\e[0m"
    sleep 0.5

    local prompt="Jesteś modułem językowym SysQCLI 'Mechanik'. Twoje JEDYNE zadanie: przepisz poniższe FAKTY na 2-3 przyjazne zdania po polsku.

FAKTY:
- Problem: $name
- Dlaczego: $expl
- Efekt: $impact
- System: ${desktop:-GNOME} na ${session:-Wayland}

ZASADY ŻELAZNE (złamanie = porażka):
1. NIE wymieniaj nazw technicznych (Qt6, SIGABRT) — opisz zjawisko zwykłym językiem
2. NIE sugeruj rozwiązań — one są już certyfikowane i pokażą się osobno
3. NIE strasz użytkownika — bądź pomocny, rzeczowy
4. ODPOWIEDZ SAMYM TEKSTEM — bez znaczników, bez formatowania

ODPOWIEDŹ (2-3 zdania):"

    local translated=$(ollama run "mechanik" "$prompt" 2>/dev/null | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g; s/\x1b\[[0-9;]*[^a-zA-Z]//g; s/\r//g' | tr -s ' \n' | head -3)

    # Badge
    local badge=""
    case "$conf" in
        certified)  badge="\e[32m✓ ROZWIĄZANIE CERTYFIKOWANE\e[0m" ;;
        community)  badge="\e[33m⚠ SUGESTIA SPOŁECZNOŚCI\e[0m" ;;
        *)          badge="\e[31m⚠ NIECERTYFIKOWANE\e[0m" ;;
    esac
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
    echo ""
    [[ -n "$translated" ]] && echo -e "\e[97m$translated\e[0m" || echo -e "$expl"
    echo ""
    echo -e "\e[1;32mRozwiązanie:\e[0m $action"
    [[ -n "$alt" ]] && echo -e "\e[1;34mAlternatywa:\e[0m $alt"
    echo ""
    echo -e "  Ryzyko:     $rbadge"
    echo -e "  Źródło:     $conf"
    [[ -n "$rollback" ]] && echo -e "  Rollback:   $rollback"
    echo ""

    # Dry-run
    if [[ $dry_run -eq 1 ]]; then
        echo -e "\e[36m[SYMULACJA] Wykonałbym: $action\e[0m"
        echo -e "\e[36m[SYMULACJA] Status: brak zmian w systemie.\e[0m"
        return
    fi

    # Prompt
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
                date +%s > "$HOME/.sysqcli_last_fix"
            else
                echo -e "\e[31m✗ Błąd wykonania (kod: $ret)\e[0m"
                [[ -n "$rollback" ]] && echo -e "\e[33mRollback: $rollback\e[0m"
            fi
        else
            echo "Anulowano."
        fi
    fi
}

# --- Helper: delegacja do Goose (v0.4) ---
_fix_delegate_to_goose() {
    if ! command -v goose &>/dev/null; then
        echo -e "\e[33mGoose nie jest dostępny.\e[0m"
        echo "Zainstaluj: pip install goose-cli"
        echo "Lub użyj fix --report i przekaż raport ręcznie."
        return 1
    fi
    echo -e "\e[35m[G] Deleguję do Goose z pełnym kontekstem...\e[0m"
    local ctx="# SysQCLI Diagnostic Report
System: $(hostname), kernel $(uname -r)
DE: ${XDG_CURRENT_DESKTOP:-?}, Session: ${XDG_SESSION_TYPE:-?}
Uptime: $(uptime -p | sed 's/up //')
GPU: $(command -v nvidia-smi &>/dev/null && echo 'nvidia' || echo 'none')

=== FAILED SERVICES ===
$(systemctl --user --failed --no-legend 2>/dev/null)
$(systemctl --failed --no-legend 2>/dev/null)

=== COREDUMPS (24h) ===
Total: $(coredumpctl list --since yesterday --no-legend 2>/dev/null | wc -l)
$(coredumpctl list --since yesterday --no-legend 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i ~ /^\//) print $i}' | sort | uniq -c | sort -rn | head -10)

=== UNIQUE ERRORS ===
$(journalctl -p 3 -xb -n 30 -o cat --no-pager 2>/dev/null | grep -vE '^\s*(#|Stack trace|Available|ELF|$)' | grep -vE '\.so\.|pthread_kill|raise|abort|PyEval|Py_Bytes|Py_Run|__libc_start' | sort -u)
"
    printf "Przeanalizuj ten raport diagnostyczny z systemu Arch Linux. Zidentyfikuj główną przyczynę problemów i zaproponuj konkretne rozwiązanie:\n\n%s" "$ctx" | goose run -i - 2>&1
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

    # Action prompt with Goose delegate option
    if [[ "$conf" == "ai_suggestion" ]]; then
        echo -e "\e[31m⚠ Rozwiązanie niecertyfikowane — SysQCLI NIE wykona go automatycznie.\e[0m"
        echo -e "Masz opcje: [R]aport  [D]eleguj  [A]nuluj"
        read "choice?► "
    else
        echo -ne "Wykonać? \e[1m[T/n/D]\e[0m "
        read -r confirm
        if [[ "$confirm" == "D" || "$confirm" == "d" ]]; then
            _fix_delegate_to_goose
        elif [[ "$confirm" == "T" || "$confirm" == "t" || -z "$confirm" ]]; then
            echo -e "\e[33mWykonuję: $action\e[0m"
            eval "$action"
            local ret=$?
            if [[ $ret -eq 0 ]]; then
                echo -e "\e[32m✓ Wykonano pomyślnie.\e[0m"
                date +%s > "$HOME/.sysqcli_last_fix"
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
            _fix_delegate_to_goose
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

# --- SYSQ SHADOW AUDIT (Shadow QC Pipeline) ---

function gem() {
    # Kolory ANSI dla UI skryptu
    local CLR_BOLD="\e[1;37m"
    local CLR_CYAN="\e[0;36m"
    local CLR_GOLD="\e[0;33m"
    local CLR_RESET="\e[0m"

    # 1. Sprawdzenie czy jesteśmy w repozytorium GIT
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo -e "${CLR_GOLD}[!] Błąd: Nie jesteś w repozytorium Git.${CLR_RESET}"
        return 1
    fi

    # 2. Pobranie zmian (staged + unstaged)
    local git_diff=$(git diff HEAD)

    # 3. Przerwanie jeśli brak zmian
    if [[ -z "$git_diff" ]]; then
        echo -e "${CLR_CYAN}[i] Brak zmian do przeanalizowania w git diff HEAD.${CLR_RESET}"
        return 0
    fi

    echo -e "${CLR_BOLD}>>> URUCHAMIANIE SHADOW QC (Asymetryczna Kontrola Jakości)...${CLR_RESET}"

    # 4. Potok do Gemini z instrukcjami sędziowskimi
    echo "$git_diff" | gemini "Działaj jako Shadow QC (Cichy Inspektor). Analizujesz 'git diff' wygenerowany przez innego agenta AI na systemie Arch Linux (CachyOS). 
Twoja ocena musi być chłodna i techniczna. Szukaj: błędnych flag basha, niebezpiecznych operacji na plikach, braku obsługi błędów, halucynacji w ścieżkach systemowych oraz luk bezpieczeństwa.

FORMAT WYNIKU (ŚCIŚLE PRZESTRZEGAĆ):
- Jeśli kod jest bezpieczny i poprawny: Zwróć wyłącznie '✓ KOD STABILNY' (kolor zielony w terminalu).
- Jeśli znajdziesz błędy: Zacznij od 'STATUS: REJECTED' i wypunktuj maksymalnie 3 najkrytyczniejsze uwagi techniczne po polsku.

DIFF DO ANALIZY:
\$(cat)" 
}

# Alias dla wygody
alias gem='gem'
