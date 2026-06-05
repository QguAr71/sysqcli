#!/usr/bin/env zsh
# ===============================================================
# SysQCLI Config v1.0 — AI (Ollama + Cache + Fix + Summary)
# ===============================================================

AI_CACHE="$HOME/.cache/sysqcli_ai"
AI_TTL=$((60*60*24))  # 24 godziny
mkdir -p "$AI_CACHE"

# --- AI: pomocnicze ---
_ai_ready() {
    command -v ollama &>/dev/null || { echo "❌ Ollama nie jest zainstalowana. Wpisz 'qinstall'."; return 1; }
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

    # Modele (dopasowane do 6GB VRAM: Q4_K_M / mini)
    local MODEL="deepseek-coder-v2:16b"   # mechanik — 8.9GB, najlżejszy coder
    case "$1" in
        -f) MODEL="phi3:mini"; shift ;;          # szybki, mały
        -pro) MODEL="qwen2.5:14b"; shift ;;      # głębszy, ~9GB, partial GPU
        -light) MODEL="qwen2.5:7b"; shift ;;    # najlżejszy, full GPU
        -cc) MODEL="deepseek-coder-v2:lite"; shift ;; # alternatywny coder
    esac

    local q="$*"
    [[ -z "$q" ]] && { echo "ai: podaj pytanie."; return 1; }

    # Cache key
    local h=$(echo "$MODEL$q" | sha256sum | cut -d' ' -f1)
    local f="$AI_CACHE/$h.md"

    _ai_cache_valid "$f" && { cat "$f"; return; }

    echo -e "\e[34m[🧠 AI: $MODEL]\e[0m"
    ollama run "$MODEL" "INSTRUKCJA: Odpowiadaj wyłącznie po polsku. $q" | tee "$f"
}

# --- Fix: AI diagnoza journalctl ---
fix() {
    _ai_ready || return 1
    echo -e "\e[33m[🔍 SysQCLI SCAN] Analizuję logi...\e[0m"
    local logs=$(journalctl -p 3 -xb -n 15 --no-pager 2>/dev/null)
    [[ -z "$logs" ]] && { echo "✅ Logi czyste."; return 0; }
    echo -e "BŁĘDY:\n$logs" | ai "Zaproponuj rozwiązanie dla Arch Linux:"
}

# --- Summary: AI podsumowanie dnia ---
summary() {
    _ai_ready || return 1
    echo -e "\e[34m[🧠 AI analizuje Twój dzień...]\e[0m"
    local hist=$(atuin history list --limit 50 2>/dev/null || fc -ln -50)
    echo -e "MOJA HISTORIA:\n$hist" | ai "Podsumuj krótko co robiłem i zasugeruj jeden przydatny alias."
}

# --- Command not found handler ---
command_not_found_handler() {
    echo -e "\e[31m[❌] Ksysqclida '$1' nie istnieje.\e[0m"
    _ai_ready && ai "Użytkownik wpisał ksysqclidę '$1', która nie istnieje. Podaj krótką sugestię naprawy." 2>/dev/null
    return 127
}

# --- Aliasy AI ---
alias sc='ai'          # DeepSeek Coder (domyślny)
alias si='ai -f'       # Phi3 mini (szybki)
alias sii='ai'         # DeepSeek Coder
alias siii='ai -pro'   # Qwen 14b (głębszy)

# --- Purge cache przy starcie ---
_ai_cache_purge
