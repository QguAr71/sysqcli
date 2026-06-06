# SysQCLI v1.1

[![Version](https://img.shields.io/badge/version-1.1-blue)](https://github.com/QguAr71/sysqcli/releases)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Arch_Linux-1793d1?logo=archlinux)](https://archlinux.org)
[![Made with](https://img.shields.io/badge/made_with-ZSH-ff69b4)](https://zsh.org)

> 📖 [English documentation (README.md)](README.md)

**Modułowa platforma konfiguracyjna ZSH z wbudowanym silnikiem diagnostycznym, mechanizmami bezpieczeństwa i opcjonalnym wsparciem AI.**

Snapshoty sesji z rollbackiem, weryfikacja integralności SHA256, trzy tryby pracy, thermal autopilot, certyfikowane wzorce diagnostyczne i integracja z AI (lokalną i chmurową). Działa na Arch Linux.

## Szybka instalacja

```bash
curl -sSL https://raw.githubusercontent.com/QguAr71/sysqcli/master/install.sh | sh
```

Lub ręcznie:

```bash
git clone https://github.com/QguAr71/sysqcli.git ~/.config/sysqcli
echo 'export SYSCLI_ROOT="$HOME/.config/sysqcli"' >> ~/.zshrc
echo 'source "$SYSCLI_ROOT/init.zsh"' >> ~/.zshrc
exec zsh
```

Przy pierwszym uruchomieniu SysQCLI sprawdza brakujące zależności. Wpisz `qinstall`, żeby je zainstalować.

Pełna instrukcja: [docs/INSTALL.pl.md](docs/INSTALL.pl.md)

## Tryby pracy

| Tryb | Aktywacja | Co działa |
|------|-----------|-----------|
| **full** (domyślny) | — | Wszystko: wtyczki, AI, monitoring, diagnostyka |
| **safe** | `qsafe` | Core + aliases + audyt. Do debugowania. |
| **immutable** | `qimmutable` | Safe + `qverify` + `chattr +i` na plikach. |

## Architektura

```
~/.config/sysqcli/
├── init.zsh          ← Punkt wejścia, logika trybów
├── core.zsh          ← PATH, EDITOR, env, kolory FZF
├── profiles.zsh      ← Automatyczna detekcja hosta (laptop/desktop)
├── deps.zsh          ← qcheck_deps + qinstall
├── qpkg.zsh          ← Abstrakcja menedżera pakietów
├── rollback.zsh      ← Snapshoty sesji + przywracanie + GC
├── integrity.zsh     ← qsign / qverify (SHA256)
├── audit.zsh         ← Audyt komend + thermal autopilot + powiadomienia
├── help.zsh          ← sysqcli() centrum pomocy
├── plugins.zsh       ← p10k + syntax highlighting + atuin/zoxide
├── visuals.zsh       ← Fastfetch + MOTD (aktualizacje, dysk, coredumpy)
├── ai.zsh            ← Ollama + silnik diagnostyczny fix() + most Goose
├── monitor.zsh       ← fkill + qhealth + qtop (btop)
├── aliases.zsh       ← zi, fn, fp, fedit, y, up, ex
├── fun.zsh           ← Pogoda
└── patterns/         ← Certyfikowane wzorce diagnostyczne (YAML)
    ├── common.yaml   ← 5 certyfikowanych wzorców (qt6, nvidia, portal, audio, oom)
    └── matcher.py    ← Silnik dopasowania (scoring + multi-hit)
```

Szczegóły modułów: [docs/MODULES.pl.md](docs/MODULES.pl.md)

## Silnik diagnostyczny (`fix`)

Komenda `fix` używa **deterministycznego, certyfikowanego systemu dopasowania wzorców** — zamiast halucynacji AI. Zbiera dane systemowe, porównuje je z bazą znanych wzorców awarii i prezentuje rozwiązanie z prostym pytaniem `[T/n]`.

### Jak działa

```
fix
  ├── 1. Zbiera dane (failed services, coredumpy, błędy journalctl, kontekst)
  ├── 2. Dopasowuje do certyfikowanych wzorców YAML (matcher.py)
  ├── 3. ZNALEZIONO → pokazuje diagnozę + ryzyko + rollback → [T/n/D]
  └── NIE ZNALEZIONO → [R]aport / [D]eleguj do Goose / [S]połeczność / [A]nuluj
```

### Komendy

| Komenda | Opis |
|---------|------|
| `fix` | Pełne skanowanie diagnostyczne + dopasowanie wzorców |
| `fix --dry-run` | Symulacja bez wykonywania zmian |
| `fix --friendly` | Lokalne AI przepisuje diagnozę na przyjazny polski |
| `fix --report` | Zapisuje pełny raport diagnostyczny do pliku |
| `fix --explain <błąd>` | Lokalne AI wyjaśnia konkretny komunikat błędu |

### Certyfikowane wzorce (5 wbudowanych)

| Wzorzec | Objawy | Ryzyko |
|---------|--------|--------|
| Qt6 + Wayland tray crash | python3.14 SIGABRT, "no Qt platform plugin" | niskie |
| NVIDIA zawieszenie po suspendzie | Czarny ekran po wybudzeniu, błędy NVRM | średnie |
| Awaria usług portalowych | Failed xdg-desktop-portal, problemy ze screenshotami | niskie |
| WirePlumber / PipeWire | Awaria dźwięku, brak audio | średnie |
| Brak pamięci (OOM) | Zabity proces, SIGKILL, OOM | brak |

Społeczność może dodawać nowe wzorce przez PR do `patterns/common.yaml`.

### Gwarancje bezpieczeństwa

- **Wszystkie komendy pochodzą z YAML**, nigdy z modelu językowego
- **Lokalne AI tylko tłumaczy** znane diagnozy na przyjazny język (`--friendly`)
- **Most Goose** (opcja `[D]`) deleguje do agenta z pełnym kontekstem
- **Każda akcja** pyta `[T/n]` przed wykonaniem
- **Komendy rollback** są pokazywane przed każdą akcją

## Główne komendy

### Bezpieczeństwo i rollback
| Komenda | Opis |
|---------|------|
| `qsign` | Podpisz wszystkie pliki .zsh sumą SHA256 |
| `qverify` | Zweryfikuj integralność plików |
| `qrestore` | Przywróć ostatni snapshot |
| `qsnaps` | Lista dostępnych snapshotów |
| `qsafe` / `qunsafe` | Przełącz tryb safe |
| `qimmutable` / `qfull` | Przełącz tryb immutable / full |
| `guard-log` | Historia guarda (zablokowane/zezwolone komendy) |

> **Security Guard:** Blokuje `rm -rf /`, `mkfs`, `dd`, fork bomby i inne niebezpieczne komendy. W trybie immutable blokuje całkowicie sudo/pacman/rm/dd.

### AI (Ollama — opcjonalne)
| Komenda | Profil |
|---------|--------|
| `sc` | mechanik (deepseek-coder-v2:16b, 23.8 t/s) |
| `si` | mini (qwen2.5:7b, 39 t/s) |
| `sii` | mechanik (to samo co sc) |
| `fix` | Silnik diagnostyczny (działa bez AI) |
| `fix --friendly` | AI tłumaczy diagnozę na przyjazny polski |
| `fix --explain` | AI wyjaśnia konkretny komunikat błędu |
| `summary` | AI podsumowuje dzień z historii atuin |

### System
| Komenda | Opis |
|---------|------|
| `up` | Super aktualizacja: pacman + AUR + modele AI + czyszczenie |
| `clean` | Czyści cache pakietów + journalctl vacuum |
| `turbo` / `eco` | Przełącza governor CPU |
| `qhealth` | Diagnostyka: temp, RAM, dysk, coredumpy, uptime |
| `qtop` | btop (monitor systemu) |
| `qtemp` | Podgląd sensors (co 2s) |
| `qgpu` | Temperatura + użycie GPU NVIDIA |
| `fkill` | Zabijanie procesów przez FZF |
| `qinstall` | Instalacja brakujących zależności |

### Nawigacja
| Komenda | Opis |
|---------|------|
| `zi` | Skoki Zoxide + FZF |
| `fn <tekst>` | Szukaj w plikach (ripgrep) → edytor |
| `fp` | Przeglądaj pliki z podglądem FZF |
| `fedit` | Wybierz plik przez FZF → edytor |
| `y` | Yazi file manager |

### Aliasy globalne (końcówki pipe)
| Alias | Efekt |
|-------|-------|
| `G` | `\| grep` |
| `L` | `\| less` |
| `M` | `\| micro` |
| `NE` | `2>/dev/null` |

## Wymagania

- ZSH 5.8+
- Arch Linux
- Pakiety: `fzf zoxide micro bat lsd fastfetch ripgrep fd` (uruchom `qinstall`)
- Opcjonalnie: `ollama` dla funkcji AI, `python-yaml` dla wzorców diagnostycznych, `goose` dla delegacji

## Współpraca

Zobacz [CONTRIBUTING.pl.md](CONTRIBUTING.pl.md) — przegląd architektury, konwencje nazewnictwa i instrukcje dodawania nowych modułów lub wzorców diagnostycznych.

## Autor

**SysQ** — https://github.com/QguAr71

## Licencja

MIT — zobacz [LICENSE](LICENSE)
