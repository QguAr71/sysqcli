# Dokumentacja modułów

## init.zsh
**Entry point.** Decyduje o kolejności ładowania, wykrywa tryb, binduje F1.
```
Przebieg:
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

**Zmienne ustawiane:**
- `SYSCLI_VERSION` — wersja
- `SYSCLI_ROOT` — ścieżka do configu
- `SYSCLI_MODE` — full/safe/immutable

## core.zsh
**Environment variables.** PATH, EDITOR, kolory FZF, terminal config.

## profiles.zsh
**Auto-detekcja hosta.** Na podstawie `hostname`:
- `omen*`, `laptop*`, `SysQ*` → laptop/eco
- `desktop*`, `ws*` → desktop/performance
- Inne → generic/balanced

## qpkg.zsh
**Abstrakcja package manager.** Wykrywa PM i dostarcza jednolity interfejs:
- `qpkg install <pkg>` — instalacja
- `qpkg upgrade` — aktualizacja
- `qpkg check` — lista dostępnych aktualizacji
- `qpkg clean` — czyszczenie cache

v2 doda obsługę apt, dnf, xbps.

## deps.zsh
**Sprawdzanie zależności.** Przy starcie sprawdza czy brakuje pakietów. `qinstall` instaluje z pacman, informuje o AUR.

## rollback.zsh
**Snapshoty sesji.** Przy każdym starcie tworzy tarball wszystkich `.zsh`. GC trzyma max 10 snapshotów.

Komendy:
- `q_snapshot` — tworzy snapshot (auto przy starcie)
- `qrestore` — przywraca ostatni snapshot
- `qsnaps` — lista dostępnych snapshotów

## integrity.zsh
**SHA256 signing.** `qsign` podpisuje wszystkie `.zsh` (oprócz init.zsh — zmienia się co sesję). `qverify` sprawdza integralność.

## audit.zsh
**Unified hook system.** Jeden `preexec` + `precmd` zamiast konfliktujących hooków:

- **preexec:** audyt komend do pliku `~/.cache/sysqcli_audit.log` + thermal autopilot (tylko full + laptop)
- **precmd:** powiadomienia dla komend trwających >10s

**Thermal autopilot:**
- >83°C → throttle ON (powersave)
- <65°C → throttle OFF (performance, jeśli był throttled)
- 78-83°C → alert

## help.zsh
**Help center.** Funkcja `sysqcli()` wyświetla pełną pomoc. F1 jest bindowane do `sysqcli`.

## plugins.zsh
**Plugin management.** Ładuje:
1. Powerlevel10k (z systemu lub OMZ)
2. zsh-autosuggestions + fast-syntax-highlighting (system paths)
3. Kolory Frosted Mint
4. Completion config
5. Atuin + Zoxide init
6. Kitty completion
7. ~/.p10k.zsh

## visuals.zsh
**Wygląd.** Fastfetch + MOTD:
- Liczba dostępnych aktualizacji
- Miejsce na dysku
- Uptime
- Coredumpy od wczoraj (warning)
- RAM >90% (warning)

MOTD wyświetla się raz na sesję (guard `SYSCLI_MOTD_SHOWN`).

## ai.zsh
**Ollama integration.** Modele dopasowane do 6GB VRAM:
- `sc` — DeepSeek Coder V2 16B (8.9 GB)
- `si` — Phi3 mini (najszybszy)
- `sii` — DeepSeek Coder (jak sc)


Cache 24h — odpowiedzi zapisywane do `~/.cache/sysqcli_ai/`, TTL 24h, auto-purge.

Funkcje:
- `ai` — zapytanie do AI
- `fix` — AI diagnoza journalctl
- `summary` — AI podsumowanie dnia (atuin history)
- `command_not_found_handler` — sugeruje poprawkę przez AI

## monitor.zsh
**Monitoring.**

- `fkill` — Process terminator przez FZF
- `qhealth` — Raport diagnostyczny: temp, RAM, dysk, aktualizacje, coredumpy, uptime, governor
- `qtop` — btop
- `qtemp` — watch sensors
- `qgpu` — nvidia-smi

## aliases.zsh
**Komendy i aliasy.**

- Podstawowe: `ls=lsd`, `cat=bat`, `top=btop`
- Globalne: `G/L/M/NE` (pipe do grep/less/micro/null)
- Tryby: `qsafe`, `qunsafe`, `qimmutable`, `qfull`
- System: `up`, `qupdate`, `clean`, `turbo`, `eco`, `ports`
- Smart extract: `ex`
- Web: `wiki`, `google`, `github`
- Nawigacja: `zi`, `fn`, `fp`, `fedit`, `y`

## fun.zsh
**Lekkie dodatki.** `pogodynka` — curl wttr.in dla Warszawy.
