# SysQCLI v1.1

[![Version](https://img.shields.io/badge/version-1.1-blue)](https://github.com/QguAr71/sysqcli/releases)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Arch_Linux-1793d1?logo=archlinux)](https://archlinux.org)
[![Made with](https://img.shields.io/badge/made_with-ZSH-ff69b4)](https://zsh.org)

> 📖 [Polska dokumentacja (README.pl.md)](README.pl.md)

**A modular ZSH configuration platform with built-in diagnostic engine, security mechanisms, and optional AI assistance.**

Session snapshots with rollback, SHA256 integrity verification, three operating modes, thermal autopilot, certified diagnostic patterns, and local/cloud AI integration. Built for Arch Linux.

## Quick Install

```bash
curl -sSL https://raw.githubusercontent.com/QguAr71/sysqcli/master/install.sh | sh
```

Or manually:

```bash
git clone https://github.com/QguAr71/sysqcli.git ~/.config/sysqcli
echo 'export SYSCLI_ROOT="$HOME/.config/sysqcli"' >> ~/.zshrc
echo 'source "$SYSCLI_ROOT/init.zsh"' >> ~/.zshrc
exec zsh
```

On first run, SysQCLI checks for missing dependencies. Type `qinstall` to install them.

Full install guide: [docs/INSTALL.md](docs/INSTALL.md)

## Operating Modes

| Mode | Activation | What works |
|------|-----------|-------------|
| **full** (default) | — | Everything: plugins, AI, monitoring, diagnostics |
| **safe** | `qsafe` | Core + aliases + audit only. For debugging. |
| **immutable** | `qimmutable` | Safe + `qverify` + `chattr +i` on files. |

## Architecture

```
~/.config/sysqcli/
├── init.zsh          ← Entry point, mode logic
├── core.zsh          ← PATH, EDITOR, env, FZF colors
├── profiles.zsh      ← Auto host detection (laptop/desktop)
├── deps.zsh          ← qcheck_deps + qinstall
├── qpkg.zsh          ← Package manager abstraction
├── rollback.zsh      ← Session snapshots + restore + GC
├── integrity.zsh     ← qsign / qverify (SHA256)
├── audit.zsh         ← Command audit + thermal autopilot + notify
├── help.zsh          ← sysqcli() help center
├── plugins.zsh       ← p10k + syntax highlighting + atuin/zoxide
├── visuals.zsh       ← Fastfetch + MOTD (updates, disk, coredumps)
├── ai.zsh            ← Ollama + fix() diagnostic engine + Goose bridge
├── monitor.zsh       ← fkill + qhealth + qtop (btop)
├── aliases.zsh       ← zi, fn, fp, fedit, y, up, ex
├── fun.zsh           ← weather utility
└── patterns/         ← Certified diagnostic patterns (YAML)
    ├── common.yaml   ← 5 certified patterns (qt6, nvidia, portal, audio, oom)
    └── matcher.py    ← Pattern matching engine (scoring + multi-hit)
```

Detailed module docs: [docs/MODULES.md](docs/MODULES.md)

## Diagnostic Engine (`fix`)

The `fix` command uses a **deterministic, certified pattern-matching system** — not AI hallucination. It collects system data, scores it against a database of known failure patterns, and presents the solution with a simple `[T/n]` prompt.

### How it works

```
fix
  ├── 1. Collect data (failed services, coredumps, journal errors, system context)
  ├── 2. Score against certified YAML patterns (matcher.py)
  ├── 3. MATCH → show diagnosis + risk + rollback → [T/n/D]
  └── NO MATCH → [R]eport / [D]elegate to Goose / [S]upport / [A]bort
```

### Commands

| Command | Description |
|---------|-------------|
| `fix` | Full diagnostic scan + pattern matching |
| `fix --dry-run` | Simulate without executing changes |
| `fix --friendly` | 16B AI translator rewrites diagnosis in natural Polish |
| `fix --report` | Save full diagnostic report to file |
| `fix --explain <error>` | Ask local AI to explain a specific error |

### Certified Patterns (5 built-in)

| Pattern | Symptoms | Risk |
|---------|----------|------|
| Qt6 + Wayland tray crash | python3.14 SIGABRT, "no Qt platform plugin" | low |
| NVIDIA suspend hang | Black screen after sleep, NVRM errors | medium |
| Portal service failure | Failed xdg-desktop-portal, screenshot issues | low |
| WirePlumber / PipeWire | Audio crash, no sound | medium |
| Out of Memory | Killed process, SIGKILL, OOM | none |

Community can submit new patterns via PR to `patterns/common.yaml`.

### Safety guarantees

- **All commands come from YAML**, never from a language model
- **16B AI only translates** known diagnoses into natural language (`--friendly`)
- **Goose bridge** (`[D]` option) delegates to a capable agent with full context
- **Every action** prompts `[T/n]` before execution
- **Rollback commands** are displayed before every action

## Key Commands

### Security & Rollback
| Command | Description |
|---------|-------------|
| `qsign` | Sign all .zsh files with SHA256 |
| `qverify` | Verify file integrity |
| `qrestore` | Restore last snapshot |
| `qsnaps` | List available snapshots |
| `qsafe` / `qunsafe` | Toggle safe mode |
| `qimmutable` / `qfull` | Toggle immutable / full mode |
| `guard-log` | Show guard history (blocked/allowed commands) |

> **Security Guard:** Blocks `rm -rf /`, `mkfs`, `dd`, fork bombs and other dangerous commands. In immutable mode, blocks sudo/pacman/rm/dd entirely.

### AI (Ollama — optional)
| Command | Profile |
|---------|---------|
| `sc` | mechanik (deepseek-coder-v2:16b, 23.8 t/s) |
| `si` | mini (qwen2.5:7b, 39 t/s) |
| `sii` | mechanik (same as sc) |
| `fix` | Diagnostic engine (works without AI) |
| `fix --friendly` | AI translates diagnosis to natural Polish |
| `fix --explain` | AI explains a specific error message |
| `summary` | AI daily summary from atuin history |

### System
| Command | Description |
|---------|-------------|
| `up` | Super update: pacman + AUR + AI models + cleanup |
| `clean` | Purge package cache + journalctl vacuum |
| `turbo` / `eco` | Toggle CPU governor |
| `qhealth` | Diagnostics: temp, RAM, disk, coredumps, uptime |
| `qtop` | btop (system monitor) |
| `qtemp` | Watch sensors output (2s interval) |
| `qgpu` | NVIDIA GPU temperature + utilization |
| `fkill` | Kill processes via FZF |
| `qinstall` | Install missing dependencies |

### Navigation
| Command | Description |
|---------|-------------|
| `zi` | Zoxide jumps + FZF |
| `fn <text>` | Search in files (ripgrep) → editor |
| `fp` | Browse files with FZF preview |
| `fedit` | Select file via FZF → editor |
| `y` | Yazi file manager |

### Global Aliases (pipe suffixes)
| Alias | Effect |
|-------|--------|
| `G` | `\| grep` |
| `L` | `\| less` |
| `M` | `\| micro` |
| `NE` | `2>/dev/null` |

## Requirements

- ZSH 5.8+
- Arch Linux
- Packages: `fzf zoxide micro bat lsd fastfetch ripgrep fd` (run `qinstall`)
- Optional: `ollama` for AI features, `python-yaml` for diagnostic patterns, `goose` for delegation

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for architecture overview, naming conventions, and how to add new modules or diagnostic patterns.

## Author

**SysQ** — https://github.com/QguAr71

## License

MIT — see [LICENSE](LICENSE)
