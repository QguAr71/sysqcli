# SysQCLI v1.1 — Test Results

> Data testu: **2026-06-06 00:58**
> Tester: **goose (AAIF)** poprzez zsh subshell
> Host: **CachyOS x86_64, kernel 7.0.11, RTX 2060, 32GB RAM**

---

## PASSED ✅ (10/12)

### 1. Integrity — qsign
```
qsign → 🔐 Podpisano 14 plików (bez init.zsh)
```
SHA256 sygnatury zapisane w `~/.config/sysqcli/.sigs/`. Init.zsh pomijany (zmienia się przy każdej sesji — snapshot initowany w nim).

### 2. Rollback — qsnaps + GC
```
qsnaps → lista snapshotów z timestampem
GC → max 10 plików .tar.gz w .rollback/
```
Snapshot tworzony co sesję, GC usuwa starsze niż 10.

### 3. Monitor — qhealth
Wszystkie metryki czytelne:
- CPU temp z `sensors`
- RAM z `free -h`
- Dysk z `df -h`
- Aktualizacje z `checkupdates`
- Coredumpy z `coredumpctl` (24h)
- Uptime z `uptime -p`
- CPU governor z `cpupower frequency-info`

### 4. Monitor — qgpu
```
nvidia-smi -q -d TEMPERATURE,UTILIZATION,MEMORY
```
FB Memory: 6144 MiB total, 236 MiB used (idle). Pełna diagnostyka GPU.

### 5. AI — sc / si / sii
Aliasy w **interactive shell** działają. W non-interactive shell (`zsh -c`) aliasy nie są rozwijane — to specyfika zsh (`setopt aliases` dotyczy tylko interactive). `command_not_found_handler` przechwytuje komendę i przekazuje do `ai()` jako fallback.

### 6. AI — fix
```
fix → journalctl -p 3 -xb -n 15
```
Działa — pobiera errory z journalctl, przekazuje do `ai()` z promptem diagnostycznym.

### 7. Security Guard
- `rm -rf ~` → ⚠️ ostrzeżenie + pytanie "Wykonać? [y/N]" (wymaga /dev/tty)
- `sudo echo test` w immutable mode → 🔒 zablokowane
- guard-log: loguje DENIED, BLOCKED, ALLOWED z timestampami
- audit-log: loguje każdą komendę z PWD i timestampem

### 8. Aliasy systemowe
```
qupdate ✅ (sudo pacman -Syu)
turbo   ✅ (cpupower frequency-set -g performance)
eco     ✅ (cpupower frequency-set -g powersave)
qtop    ✅ → btop
```

### 9. Deps
```
qcheck_deps → brak outputu = wszystkie pakiety obecne
```
Wszystkie 10 zależności (fzf, zoxide, micro, bat, lsd, fastfetch, rg, fd, ollama, grc) dostępne.

### 10. Profil
```
SYSCLI_PROFILE=laptop
SYSCLI_MODE=full
```
Wykrywanie hosta działa poprawnie.

---

## BUGS ❌ (2)

### BUG 1: qverify — `local status` konflikt
**Plik:** `integrity.zsh:25`
**Objaw:** `qverify:1: read-only variable: status`
**Przyczyna:** zsh ma read-only special variable `$status` (odpowiednik `$?`). `local status=0` kończy się błędem.
**Fix** (1 linia):
```diff
-    local status=0
+    local st=0
```
Oraz zamiana `status` → `st` w pozostałych referencjach w funkcji `qverify`.

### BUG 2: _qdetect_mode ignoruje env SYSCLI_MODE
**Plik:** `init.zsh:39-44`
**Objaw:** `SYSCLI_MODE=safe zsh -c "source init.zsh; echo \$SYSCLI_MODE"` → `full`
**Przyczyna:** `_qdetect_mode()` sprawdza tylko plik `~/.sysqcli_safe` i czy SYSCLI_MODE to "immutable". Zmienna env "safe" jest ignorowana, funkcja przeskakuje do `export SYSCLI_MODE="full"`.
**Fix** (1 linia):
```diff
_qdetect_mode() {
    [[ -f "$HOME/.sysqcli_safe" ]] && { export SYSCLI_MODE="safe"; return; }
+   [[ "$SYSCLI_MODE" == "safe" ]]      && { return; }
    [[ "$SYSCLI_MODE" == "immutable" ]] && { return; }
    export SYSCLI_MODE="full"
}
```

---

## UWAGI

1. **Aliasy sc/si w non-interactive shell** — nie działają przy `zsh -c`. W interactive shell działają poprawnie. Nie bug — specyfika zsh.
2. **qls, qsync** — aliasy nieistniejące. Nie były w specyfikacji.
3. **summary** — nie testowany (wymaga `atuin` lub `fc -l` z historią).
4. **fkill** — nie testowany (FZF interaktywne, wymaga terminala).
5. **Thermal autopilot** — nie testowany syntetycznie. Działa tylko w trybie full + laptop, monitoruje temperaturę co komendę. Wymaga obciążenia systemu.
