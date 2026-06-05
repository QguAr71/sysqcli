#!/usr/bin/env zsh
# ===============================================================
# SysQCLI Config v1.0 — INTEGRITY (SHA256 Sign + Verify)
# ===============================================================

SIGDIR="$SYSCLI_ROOT/.sigs"
mkdir -p "$SIGDIR"

# --- SIGN: podpisz wszystkie .zsh ---
qsign() {
    local sig count=0
    for f in "$SYSCLI_ROOT"/*.zsh; do
        [[ "$(basename "$f")" == "init.zsh" ]] && continue  # init się zmienia co sesję
        sig="$SIGDIR/$(basename "$f").sig"
        sha256sum "$f" > "$sig"
        ((count++))
    done
    echo "🔐 Podpisano $count plików (bez init.zsh)"
}

# --- VERIFY: sprawdź integralność ---
qverify() {
    local st=0
    for f in "$SYSCLI_ROOT"/*.zsh; do
        [[ "$(basename "$f")" == "init.zsh" ]] && continue
        [[ ! -f "$SIGDIR/$(basename "$f").sig" ]] && continue
        sha256sum -c "$SIGDIR/$(basename "$f").sig" --status 2>/dev/null || {
            echo "❌ NARUSZENIE: $(basename "$f")"
            st=1
        }
    done
    [[ $st -eq 0 ]] && echo "✅ Integralność OK" || return 1
}
