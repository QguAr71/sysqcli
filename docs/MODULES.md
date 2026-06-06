# Module Documentation

> 📖 [Polska wersja (MODULES.pl.md)](MODULES.pl.md)

## init.zsh
**Entry point.** Controls load order, detects operating mode, binds F1 to help.
```
Flow:
  1. Snapshot (rollback)
  2. Profile (host detection)
  3. Core (env)
  4. QPKG (PM detection)
  5. Deps (check)
  6. Integrity
  7. Help (F1 bind)
  8. MODE DECISION:
     ├── safe      → audit + aliases → return
     ├── immutable → audit + aliases + qverify + chattr +i → return
     └── full      → audit + plugins + visuals + ai + monitor + aliases + fun
```

**Variables set:**
- `SYSCLI_VERSION` — version
- `SYSCLI_ROOT` — config path
- `SYSCLI_MODE` — full/safe/immutable

## core.zsh
**Environment variables.** PATH, EDITOR, FZF color scheme, terminal config.

## profiles.zsh
**Auto host detection.** Based on `hostname`:
- `omen*`, `laptop*`, `SysQ*` → laptop/eco
- `desktop*`, `ws*` → desktop/performance
- Other → generic/balanced

## qpkg.zsh
**Package manager abstraction.** Detects PM and provides unified interface:
- `qpkg install <pkg>` — install
- `qpkg upgrade` — update
- `qpkg check` — list available updates
- `qpkg clean` — clean cache

v2 will add apt, dnf, xbps support.

## deps.zsh
**Dependency checking.** On startup, checks for missing packages. `qinstall` installs from pacman and reports AUR packages.

## rollback.zsh
**Session snapshots.** Creates a tarball of all `.zsh` files on each session start. GC keeps max 10 snapshots.

Commands:
- `q_snapshot` — create snapshot (auto on start)
- `qrestore` — restore last snapshot
- `qsnaps` — list available snapshots

## integrity.zsh
**SHA256 signing.** `qsign` signs all `.zsh` files (excluding init.zsh — changes every session). `qverify` checks integrity.

## audit.zsh
**Unified hook system.** Single `preexec` + `precmd` instead of conflicting hooks:

- **preexec:** command audit to `~/.cache/sysqcli_audit.log` + thermal autopilot (full mode + laptop only)
- **precmd:** desktop notifications for commands running >10s

**Thermal autopilot:**
- >83°C → throttle ON (powersave)
- <65°C → throttle OFF (performance, if was throttled)
- 78-83°C → alert

## help.zsh
**Help center.** `sysqcli` function displays full help. F1 is bound to it.

## plugins.zsh
**Plugin management.** Loads:
1. Powerlevel10k (system or OMZ path)
2. zsh-autosuggestions + fast-syntax-highlighting (system paths)
3. Frosted Mint color scheme
4. Completion config
5. Atuin + Zoxide init
6. Kitty completion
7. ~/.p10k.zsh

## visuals.zsh
**Appearance.** Fastfetch + MOTD:
- Available updates count
- Disk usage
- Uptime
- Coredumps since yesterday (warning)
- RAM >90% (warning)

MOTD shows once per session (guard: `SYSCLI_MOTD_SHOWN`).

## ai.zsh
**Ollama integration + certified diagnostic engine.** Profiles optimized for 6GB VRAM:
- `mechanik` — deepseek-coder-v2:16b Q4_0, 8.9 GB, 23.8 t/s
- `mini` — qwen2.5:7b Q4_K_M, 4.7 GB full GPU, 39 t/s

24h cache — responses stored in `~/.cache/sysqcli_ai/`, auto-purge.

### Diagnostic Engine (`fix`)
Uses **deterministic YAML pattern matching** — not AI hallucination:
1. Modular collectors gather data (`systemctl failed`, `coredumpctl`, `journalctl`, system context)
2. `matcher.py` scores against `patterns/common.yaml` (5 certified patterns)
3. MATCH → shows diagnosis + risk + rollback → `[T/n/D]`
4. NO MATCH → `[R]eport / [D]elegate to Goose / [S]upport / [A]bort`

| Command | What it does |
|---------|-------------|
| `fix` | Full diagnostic scan + pattern matching |
| `fix --dry-run` | Simulate without executing |
| `fix --friendly` | 16B AI translates YAML diagnosis to natural Polish |
| `fix --report` | Save full diagnostic report with system context |
| `fix --explain <error>` | AI explains a specific error message |

**Safety:** All executable commands come from YAML, never from the language model. The 16B AI only rewrites text for `--friendly` mode.

### AI Functions
- `ai` / `sc` — query mechanik
- `si` — query mini (fast)
- `summary` — AI daily summary from atuin history
- `command_not_found_handler` — suggests fix via AI

## monitor.zsh
**Monitoring.**

- `fkill` — Process terminator via FZF
- `qhealth` — Diagnostic report: temp, RAM, disk, updates, coredumps, uptime, governor
- `qtop` — btop
- `qtemp` — watch sensors
- `qgpu` — nvidia-smi

## aliases.zsh
**Commands and aliases.**

- Basic overrides: `ls=lsd`, `cat=bat`, `top=btop`
- Global pipe suffixes: `G/L/M/NE` (grep/less/micro/null)
- Modes: `qsafe`, `qunsafe`, `qimmutable`, `qfull`
- System: `up`, `qupdate`, `clean`, `turbo`, `eco`, `ports`
- Smart extract: `ex`
- Web search: `wiki`, `google`, `github`
- Navigation: `zi`, `fn`, `fp`, `fedit`, `y`

## fun.zsh
**Light extras.** `pogodynka` — curl wttr.in for Warsaw.

## patterns/
**Certified diagnostic patterns.** YAML database of known failure patterns with safe repair procedures.

- `common.yaml` — 5 certified patterns:
  - Qt6 + Wayland tray crash (`arch-update-tray`)
  - NVIDIA suspend hang (`nvidia-modeset`)
  - Portal service failure (`xdg-desktop-portal`)
  - WirePlumber / PipeWire audio crash
  - Out of Memory (OOM) killer
- `matcher.py` — Python 3 + PyYAML scoring engine:
  - service match: +5
  - exe match: +4
  - signal match: +3
  - error match: +3
  - multi-hit bonus: +2 per extra match type
  - threshold: score ≥ 4

**Structure:** Each pattern includes `explanation`, `impact`, `recommended_action`, `risk`, `rollback`, `alternative`, `references`, and `confidence` level (`certified`/`community`/`ai_suggestion`). Community can add new patterns via PR.
