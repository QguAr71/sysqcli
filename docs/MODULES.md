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
**Ollama integration.** Profiles optimized for 6GB VRAM:
- `mechanik` — deepseek-coder-v2:16b Q4_0, 8.9 GB, 23.8 t/s (debug code/logs)
- `mini` — qwen2.5:7b Q4_K_M, 4.7 GB full GPU, 39 t/s (fast diagnostics)


24h cache — responses stored in `~/.cache/sysqcli_ai/`, auto-purge.

Functions:
- `ai` — query AI
- `fix` — AI diagnosis of journalctl
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
