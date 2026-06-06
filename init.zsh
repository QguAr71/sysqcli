#!/usr/bin/env zsh
# ===============================================================
# SysQCLI Config v1.0 — INIT (Entry Point)
# ===============================================================
# Kolejność: snapshot  profile  core  deps  rollback  integrity
#             MODE CHECK  audit  [full: plugins/visuals/ai/monitor]  aliases
# ===============================================================

export SYSCLI_VERSION="1.1"
export SYSCLI_ROOT="${SYSCLI_ROOT:-$HOME/.config/sysqcli}"

# --- 0. USER CONFIG (~/.sysqclirc) ---
[[ -f "$HOME/.sysqclirc" ]] && source "$HOME/.sysqclirc"

# --- 1. SNAPSHOT (zawsze, przed wszystkim) ---
source "$SYSCLI_ROOT/rollback.zsh"
q_snapshot

# --- 2. PROFIL (host detection) ---
source "$SYSCLI_ROOT/profiles.zsh"

# --- 3. CORE (PATH, EDITOR, env, kolory) ---
source "$SYSCLI_ROOT/core.zsh"

# --- 4. QPKG (abstrakcja package manager) ---
source "$SYSCLI_ROOT/qpkg.zsh"

# --- 5. DEPS (sprawdzanie zależności + qinstall) ---
source "$SYSCLI_ROOT/deps.zsh"
qcheck_deps

# --- 6. INTEGRITY (qsign/qverify, zawsze dostępne) ---
source "$SYSCLI_ROOT/integrity.zsh"

# --- 7. HELP (sysqcli, F1 — zawsze dostępne, nawet safe/immutable) ---
source "$SYSCLI_ROOT/help.zsh"

# === DETEKCJA TRYBU ===
_qdetect_mode() {
    [[ -f "$HOME/.sysqcli_safe" ]] && { export SYSCLI_MODE="safe"; return; }
    [[ "$SYSCLI_MODE" == "safe" ]]      && { return; }
    [[ "$SYSCLI_MODE" == "immutable" ]] && { return; }
    export SYSCLI_MODE="full"
}
_qdetect_mode

# === TRYB: SAFE ===
if [[ "$SYSCLI_MODE" == "safe" ]]; then
    source "$SYSCLI_ROOT/audit.zsh"
    source "$SYSCLI_ROOT/aliases.zsh"
    echo -e "\e[1;33m\uf0c3 SysQCLI v$SYSCLI_VERSION | SAFE MODE | profil: $SYSCLI_PROFILE | Tylko minimum\e[0m"
    return 0
fi

# === TRYB: IMMUTABLE ===
if [[ "$SYSCLI_MODE" == "immutable" ]]; then
    source "$SYSCLI_ROOT/audit.zsh"
    source "$SYSCLI_ROOT/aliases.zsh"
    qverify || true
    chattr +i "$SYSCLI_ROOT"/*.zsh 2>/dev/null
    echo -e "\e[1;31m SysQCLI v$SYSCLI_VERSION | IMMUTABLE MODE | Pliki zablokowane (chattr +i)\e[0m"
    return 0
fi

# === TRYB: FULL (domyślny) ===
source "$SYSCLI_ROOT/audit.zsh"
[[ -z "$SYSCLI_NO_PLUGINS" ]]  && source "$SYSCLI_ROOT/plugins.zsh"
[[ -z "$SYSCLI_NO_VISUALS" ]]  && source "$SYSCLI_ROOT/visuals.zsh"
[[ -z "$SYSCLI_NO_AI" ]]       && source "$SYSCLI_ROOT/ai.zsh"
[[ -z "$SYSCLI_NO_MONITOR" ]]  && source "$SYSCLI_ROOT/monitor.zsh"
source "$SYSCLI_ROOT/aliases.zsh"
[[ -z "$SYSCLI_NO_FUN" ]]      && source "$SYSCLI_ROOT/fun.zsh"

echo -e "\e[1;34m SysQCLI v$SYSCLI_VERSION | FULL MODE | profil: $SYSCLI_PROFILE | Power: $SYSCLI_POWER\e[0m"
