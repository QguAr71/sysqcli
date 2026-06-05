# Contributing to SysQCLI

> 📖 [Polska wersja (CONTRIBUTING.pl.md)](CONTRIBUTING.pl.md)

## Architecture

SysQCLI is **modular** — each `.zsh` file is a standalone module with a single responsibility.

```
init.zsh           # Entry point — avoid editing unless adding new modules
├── rollback.zsh   # Snapshots + restore
├── profiles.zsh   # Host detection
├── core.zsh       # Environment variables
├── deps.zsh       # Dependency checking
├── qpkg.zsh       # Package manager abstraction
├── integrity.zsh  # SHA256 signing
├── help.zsh       # Help center (sysqcli function)
├── audit.zsh      # preexec/precmd hooks (audit + thermal + notify)
├── plugins.zsh    # ZSH plugins (p10k, syntax highlighting)
├── visuals.zsh    # Fastfetch + MOTD
├── ai.zsh         # Ollama integration
├── monitor.zsh    # fkill + qhealth
├── aliases.zsh    # Command aliases
└── fun.zsh        # Non-essential utilities
```

## Conventions

### Environment Variables
- **`SYSCLI_*` prefix** — exported, used across multiple modules
- **`local`** — inside functions only

### Function Naming
- `q*` — user-facing commands (`qsign`, `qverify`, `qhealth`)
- `_q*` — internal module functions (`_qpkg_detect`, `_ai_cache_valid`)
- `_*` — private helpers

### Style
- 80 columns where practical
- `# --- Section ---` for logical groups
- English comments in code, user messages in the user's language

## Adding a New Module

1. Create `name.zsh` in the root directory
2. Add `source "$SYSCLI_ROOT/name.zsh"` in `init.zsh` in the appropriate section
3. Document in `docs/MODULES.md`
4. Add relevant help entries in `help.zsh`

## Testing

```bash
# Syntax check
zsh -n new_module.zsh

# Full test — reloads SysQCLI
exec zsh

# Scripted load test (no side effects)
zsh -c 'export SYSCLI_ROOT="$HOME/.config/sysqcli"; source "$SYSCLI_ROOT/init.zsh"'
```

## CI

GitHub Actions runs `zsh -n` on every push and PR. All `.zsh` files must pass syntax check.

## Roadmap

- [ ] v2: multi-distro support (apt, dnf, xbps) in `qpkg.zsh`
- [ ] v2: language-aware AI prompts (not hardcoded Polish)
- [ ] `~/.sysqclirc` — user config without editing `init.zsh`
- [ ] One-line installer (`curl | sh`)
- [ ] Integration tests (mode start verification)
