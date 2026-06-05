# SysQCLI v1.0

[![Version](https://img.shields.io/badge/version-1.0-blue)](https://github.com/QguAr71/sysqcli/releases)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Arch_Linux-1793d1?logo=archlinux)](https://archlinux.org)
[![Made with](https://img.shields.io/badge/made_with-ZSH-ff69b4)](https://zsh.org)
[![CI](https://img.shields.io/badge/CI-passing-brightgreen)](https://github.com/QguAr71/sysqcli/actions)

**Modularna platforma konfiguracyjna ZSH z mechanizmami bezpieczeństwa.**

Rollback snapshotów, integralność SHA256, trzy tryby pracy, termiczny autopilot, integracja z AI (Ollama) i monitoring HUD. Stworzona dla Arch Linux z myślą o wielodystrybucyjności w v2.

## Instalacja

```bash
git clone https://github.com/QguAr71/sysqcli.git ~/.config/sysqcli
echo 'export SYSCLI_ROOT="$HOME/.config/sysqcli"' >> ~/.zshrc
echo 'source "$SYSCLI_ROOT/init.zsh"' >> ~/.zshrc
exec zsh
```

## Tryby pracy

| Tryb | Aktywacja | Co działa |
|------|-----------|-----------|
| **full** (domyślny) | — | Wszystko: pluginy, AI, HUD, monitoring |
| **safe** | `qsafe` | Tylko core + aliases + audyt. Do debugowania. |
| **immutable** | `qimmutable` | Safe + `qverify` + `chattr +i` na plikach. Nie zmienisz configu bez drugiego terminala. |

## Struktura

```
~/.config/sysqcli/
├── init.zsh          ← Entry point, logika trybów, F1 → help
├── core.zsh          ← PATH, EDITOR, env, kolory FZF
├── profiles.zsh      ← Auto-detekcja hosta (laptop/desktop)
├── deps.zsh          ← qcheck_deps + qinstall
├── qpkg.zsh          ← Abstrakcja package manager (v2 multi-distro)
├── rollback.zsh      ← Snapshot każdej sesji + restore + GC
├── integrity.zsh     ← qsign / qverify (SHA256)
├── audit.zsh         ← Audyt komend + termiczny autopilot + notify
├── help.zsh          ← sysqcli() help center, bind F1
├── plugins.zsh       ← p10k + syntax highlighting + atuin/zoxide
├── visuals.zsh       ← Fastfetch + MOTD (aktualizacje, dysk, coredumpy)
├── ai.zsh            ← Ollama + cache 24h + fix + summary + cmd handler
├── monitor.zsh       ← HUD (paski CPU/RAM) + fkill + qhealth
├── aliases.zsh       ← zi, fn, fp, fedit, y, up, ex, wiki, G/L/M/NE
└── fun.zsh           ← pogodynka
```

## Kluczowe komendy

### Bezpieczeństwo
| Komenda | Opis |
|---------|------|
| `qsign` | Podpisz wszystkie pliki SHA256 |
| `qverify` | Sprawdź integralność |
| `qrestore` | Przywróć ostatni snapshot |
| `qsnaps` | Lista snapshotów |
| `qsafe` / `qunsafe` | Przełącz tryb awaryjny |
| `qimmutable` / `qfull` | Immutable / Full mode |

### AI (Ollama)
| Komenda | Model |
|---------|-------|
| `sc` | DeepSeek Coder V2 16B |
| `si` | Phi3 mini (szybki) |
| `sii` | DeepSeek Coder (jak sc) |
| `siii` | Qwen 2.5 14B (głębszy) |
| `fix` | AI diagnoza journalctl |
| `summary` | AI podsumowanie dnia z atuin |

### System
| Komenda | Opis |
|---------|------|
| `up` | Super update: pacman + AUR + AI modele + clean |
| `clean` | paccache + journalctl vacuum |
| `turbo` / `eco` | Przełącz governor CPU |
| `qhealth` | Diagnostyka: temp, RAM, dysk, coredumpy, uptime |
| `hud` | Live monitor (paski CPU/RAM, temp, MHz) |
| `fkill` | Zabij proces przez FZF |
| `qinstall` | Zainstaluj brakujące zależności |

### Nawigacja
| Komenda | Opis |
|---------|------|
| `zi` | Skoki Zoxide + FZF |
| `fn <tekst>` | Szukaj w plikach (ripgrep) → micro |
| `fp` | Przeglądaj pliki FZF z podglądem |
| `fedit` | Wybierz plik FZF → micro |
| `y` | Yazi file manager |

### Globalne aliasy (suffix)
| Alias | Efekt |
|-------|-------|
| `G` | `\| grep` |
| `L` | `\| less` |
| `M` | `\| micro` |
| `NE` | `2>/dev/null` |

## Wymagania

- ZSH 5.8+
- Arch Linux (v2: multi-distro)
- pakiety: `fzf zoxide micro bat lsd fastfetch ripgrep fd` (patrz `qinstall`)

## Autor

**SysQ** — https://github.com/QguAr71

## Licencja

MIT
