# SysQCLI v1.0

[![Version](https://img.shields.io/badge/version-1.0-blue)](https://github.com/QguAr71/sysqcli/releases)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Arch_Linux-1793d1?logo=archlinux)](https://archlinux.org)
[![Made with](https://img.shields.io/badge/made_with-ZSH-ff69b4)](https://zsh.org)
[![CI](https://github.com/QguAr71/sysqcli/actions/workflows/ci.yml/badge.svg)](https://github.com/QguAr71/sysqcli/actions/workflows/ci.yml)

![SysQCLI demo](demo.gif)

> 📖 [Polska dokumentacja (README.pl.md)](README.pl.md)

**A modular ZSH configuration platform with built-in security mechanisms.**

Session snapshots with rollback, SHA256 integrity verification, three operating modes, thermal autopilot, local AI integration (Ollama), and system monitoring. Built for Arch Linux with multi-distro support planned for v2.

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
| **full** (default) | — | Everything: plugins, AI, monitoring |
| **safe** | `qsafe` | Core + aliases + audit only. For debugging. |
| **immutable** | `qimmutable` | Safe + `qverify` + `chattr +i` on files. Cannot modify config without a second terminal. |

## Architecture

```
~/.config/sysqcli/
├── init.zsh          ← Entry point, mode logic, F1 → help
├── core.zsh          ← PATH, EDITOR, env, FZF colors
├── profiles.zsh      ← Auto host detection (laptop/desktop)
├── deps.zsh          ← qcheck_deps + qinstall
├── qpkg.zsh          ← Package manager abstraction (v2 multi-distro)
├── rollback.zsh      ← Session snapshots + restore + GC
├── integrity.zsh     ← qsign / qverify (SHA256)
├── audit.zsh         ← Command audit + thermal autopilot + notify
├── help.zsh          ← sysqcli() help center, F1 bind
├── plugins.zsh       ← p10k + syntax highlighting + atuin/zoxide
├── visuals.zsh       ← Fastfetch + MOTD (updates, disk, coredumps)
├── ai.zsh            ← Ollama + 24h cache + fix + summary + cmd handler
├── monitor.zsh       ← fkill + qhealth + qtop (btop)
├── aliases.zsh       ← zi, fn, fp, fedit, y, up, ex, wiki, G/L/M/NE
└── fun.zsh           ← weather utility
```

Detailed module docs: [docs/MODULES.md](docs/MODULES.md)

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

### AI (Ollama)
| Command | Profile |
|---------|---------|
| `sc` | mechanik (deepseek-coder-v2:16b, 23.8 t/s) |
| `si` | mini (qwen2.5:7b, 39 t/s) |
| `sii` | mechanik (same as sc) |
| `siii` | normal (qwen2.5:14b, 5.3 t/s) |
| `fix` | AI diagnosis of journalctl |
| `summary` | AI daily summary from atuin history |

### System
| Command | Description |
|---------|-------------|
| `up` | Super update: pacman + AUR + AI models + cleanup |
| `clean` | Purge package cache + journalctl vacuum |
| `turbo` / `eco` | Toggle CPU governor |
| `qhealth` | Diagnostics: temp, RAM, disk, coredumps, uptime |
| `qtop` | btop (system monitor) |
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
- Arch Linux (multi-distro: v2)
- Packages: `fzf zoxide micro bat lsd fastfetch ripgrep fd` (run `qinstall`)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for architecture overview, naming conventions, and how to add new modules.

## Author

**SysQ** — https://github.com/QguAr71

## License

MIT — see [LICENSE](LICENSE)
