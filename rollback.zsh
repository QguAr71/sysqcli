#!/usr/bin/env zsh
# ===============================================================
# SysQCLI Config v1.0 — ROLLBACK (Snapshot + Restore + GC)
# ===============================================================

ROLLBACK_DIR="$SYSCLI_ROOT/.rollback"
ROLLBACK_MAX=10
mkdir -p "$ROLLBACK_DIR"

# --- SNAPSHOT (każda sesja) ---
q_snapshot() {
    local ts=$(date +%Y%m%d_%H%M%S)
    tar -czf "$ROLLBACK_DIR/$ts.tar.gz" "$SYSCLI_ROOT"/*.zsh 2>/dev/null

    # GC: keep only last N
    local count=$(ls -1 "$ROLLBACK_DIR"/*.tar.gz 2>/dev/null | wc -l)
    if (( count > ROLLBACK_MAX )); then
        ls -1t "$ROLLBACK_DIR"/*.tar.gz | tail -n +$((ROLLBACK_MAX + 1)) | xargs rm -f
    fi
}

# --- RESTORE (z FZF do wyboru snapshota) ---
qrestore() {
    local files=($(ls -1t "$ROLLBACK_DIR"/*.tar.gz 2>/dev/null))
    [[ ${#files} -eq 0 ]] && { echo " Brak snapshotów."; return 1; }

    local chosen
    if (( ${#files} == 1 )); then
        chosen="${files[1]}"
    else
        chosen=$(for f in "${files[@]}"; do
            echo "$(basename $f .tar.gz)"
        done | fzf --height 40% --layout=reverse --header="Wybierz snapshot do przywrócenia")
        [[ -z "$chosen" ]] && return 0
        chosen="$ROLLBACK_DIR/${chosen}.tar.gz"
    fi

    echo "Przywracam: $(basename $chosen .tar.gz)..."
    tar -xzf "$chosen" -C "$HOME/" 2>/dev/null && \
        echo "\uf1b8 Przywrócono: $(basename $chosen)" || \
        echo " Błąd przywracania"
}
q_restore_last() {
    local last=$(ls -t "$ROLLBACK_DIR"/*.tar.gz 2>/dev/null | head -1)
    [[ -z "$last" ]] && { echo " Brak snapshotów."; return 1; }
    tar -xzf "$last" -C "$HOME/"
    echo "\uf1b8 Przywrócono: $(basename $last)"
}

# --- LIST (snapshoty) ---
qsnaps() {
    ls -1t "$ROLLBACK_DIR"/*.tar.gz 2>/dev/null | while read f; do
        echo "  $(basename $f .tar.gz)"
    done
}
