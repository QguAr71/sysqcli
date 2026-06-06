# SysQCLI Roadmap

> Ostatnia aktualizacja: 2026-06-06

## ✅ v1.0 — Core Platform (done)

- [x] Modułowa architektura (15 modułów ZSH)
- [x] Trzy tryby pracy (full/safe/immutable)
- [x] Security Guard (blokada niebezpiecznych komend)
- [x] Snapshoty sesji + rollback (SHA256)
- [x] Thermal autopilot (CPU throttle/recovery)
- [x] Ollama integracja (2 profile: mechanik/mini)
- [x] qhealth / fkill / qtop / qtemp / qgpu
- [x] Aliases + FZF nawigacja + global pipe suffixes

---

## ✅ v1.1 — Diagnostic Engine (2026-06-06, done)

- [x] Deterministic pattern matching (`fix`)
- [x] 5 certified YAML patterns (`patterns/common.yaml`)
- [x] Scoring engine `matcher.py` (service+5, exe+4, signal+3, error+3)
- [x] `fix --dry-run` (symulacja bez wykonywania)
- [x] `fix --friendly` (16B AI translator — YAML → przyjazny PL)
- [x] `fix --report` (pełny raport diagnostyczny z kontekstem)
- [x] `fix --explain <błąd>` (AI wyjaśnia konkretny error)
- [x] Goose bridge (`[D]eleguj` w każdym flow)
- [x] Stale throttle fix (`.sysqcli_throttled` + init check)
- [x] `qhealth`: LANG=C free + cpupower awk fix
- [x] Modułowe collectory (`_collect_systemd_failed`, `_collect_coredumps`, etc.)
- [x] System context w raporcie (kernel, DE, session, GPU, uptime)
- [x] Multi-hit scoring bonus w matcher.py
- [x] Repo publiczne
- [x] Dokumentacja PL + EN

---

## 🔜 v1.2 — More Certified Patterns

Cel: **10–15 wzorców** → pokrycie 90% typowych awarii.

| # | Pattern | Priorytet |
|---|---------|-----------|
| 6 | NVIDIA OOM / `nvidia-modeset` suspend freeze (rozszerzenie istniejącego) | high |
| 7 | Flatpak portal conflicts | high |
| 8 | systemd-oomd false positives | medium |
| 9 | GPU fallback → llvmpipe po aktualizacji sterownika | medium |
| 10 | pacman lockfile stale (`/var/lib/pacman/db.lck`) | high |
| 11 | DBus session timeout (częsty na laptopach) | medium |
| 12 | PulseAudio ↔ PipeWire konflikt | low |
| 13 | `/tmp` full (tmpfs overflow) | medium |
| 14 | `~/.cache` ballooning (>10GB) | low |
| 15 | NVIDIA kernel module mismatch po aktualizacji | high |

**Format:** Każdy wzorzec = wpis w `patterns/common.yaml` + test na realnym systemie.

---

## 🔜 v1.3 — Ranking Engine

Problem: przy 15+ wzorcach prosty `score ≥ 4` nie wystarczy. Kilka patternów może mieć podobny score.

Rozwiązanie:
- Top-k ranking zamiast pojedynczego thresholdu
- Margin confidence: różnica między #1 a #2
- Wyświetlanie: "pewny na 95%" vs "2 możliwe wyjaśnienia"
- `fix --all` — pokaż wszystkie pasujące wzorce posortowane po score

---

## 🔜 v1.4 — Cloud Delegation & Passive Monitor

### Cloud delegation
- `fix --delegate cloud` — wysyła ustrukturyzowany JSON do Gemini/GPT API
- Działa tylko gdy `NO_MATCH` lub user jawnie zażąda
- Odpowiedź oznaczona `confidence: ai_suggestion` (nigdy nie wykonywana automatycznie)
- Konfiguracja API key w `~/.sysqclirc`

### Pasywne monitorowanie (health timer)
- `sysqcli-health.timer` + `sysqcli-health.service` (systemd user unit)
- Co godzinę: sprawdza coredumpy + failed units
- Nowy problem → `notify-send` + opcjonalnie `fix --dry-run` w tle
- `systemctl --user enable sysqcli-health.timer` — jedna komenda aktywacji

---

## 🔜 v1.5 — Community, Release & i18n

### Release v1.1 (stabilna)
- Tag `v1.1` na GitHub
- GitHub Release z changelogiem (PL + EN)
- `install.sh` gotowy do `curl | sh`
- AUR package? (`sysqcli-git`)

### Internacjonalizacja (i18n)
- Angielski jako język źródłowy (hardcoded w kodzie)
- `messages/pl.sh` — katalog tłumaczeń na polski
- `~/.sysqclirc`: `SYSCLI_LANG=pl|en` (domyślnie: `LANG` z systemu)
- Nowe moduły pisane od razu po angielsku
- Później: instalator pobiera tylko wybraną wersję językową (gdy przybędzie języków)

### Community
- Szablon PR dla nowych wzorców (`patterns/`)
- `fix --add-pattern` — interaktywny kreator nowego wzorca
- CI/CD: `fix --dry-run --all` jako test regresyjny
- Tablica `Discussions` na GitHub

---

## 📋 Backlog (v2.0+)

- Multi-distro: Fedora, Ubuntu, Debian
- `qpkg.zsh` — detekcja apt/dnf/pacman
- Testy regresyjne dla matcher.py (ciężkie: sztuczne logi + expected matches)
- Web dashboard? (opcjonalnie, TUI-first)

---

## Wersjonowanie modułów

| Moduł | v1.0 | v1.1 | v1.2 | v1.4 |
|-------|------|------|------|------|
| ai.zsh | — | fix() | stale throttle | YAML + matcher + Goose |
| audit.zsh | — | — | flag file + init | — |
| monitor.zsh | — | LANG=C + awk | — | — |
| matcher.py | — | — | — | v1.0 (scoring) |

Zasada: każdy moduł ma wersję w nagłówku, zmiana = bump. Wersja globalna = najwyższa wersja modułu.
