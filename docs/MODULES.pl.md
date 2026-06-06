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
**Integracja Ollama + silnik diagnostyczny.** Modele dopasowane do 6GB VRAM:
- `mechanik` — deepseek-coder-v2:16b Q4_0, 8.9 GB, 23.8 t/s
- `mini` — qwen2.5:7b Q4_K_M, 4.7 GB full GPU, 39 t/s

Cache 24h — odpowiedzi zapisywane do `~/.cache/sysqcli_ai/`, TTL 24h, auto-purge.

### Silnik diagnostyczny (`fix`)
Używa **deterministycznego dopasowania wzorców YAML** — nie halucynacji AI:
1. Modułowe collectory zbierają dane (`systemctl failed`, `coredumpctl`, `journalctl`, kontekst)
2. `matcher.py` porównuje z `patterns/common.yaml` (5 certyfikowanych wzorców)
3. ZNALEZIONO → pokazuje diagnozę + ryzyko + rollback → `[T/n/D]`
4. NIE ZNALEZIONO → `[R]aport / [D]eleguj do Goose / [S]połeczność / [A]nuluj`

| Komenda | Działanie |
|---------|----------|
| `fix` | Pełne skanowanie diagnostyczne + dopasowanie wzorców |
| `fix --dry-run` | Symulacja bez wykonywania zmian |
| `fix --friendly` | Lokalne AI tłumaczy diagnozę na przyjazny polski |
| `fix --report` | Zapisuje pełny raport diagnostyczny z kontekstem |
| `fix --explain <błąd>` | AI wyjaśnia konkretny komunikat błędu |

**Bezpieczeństwo:** Wszystkie wykonywalne komendy pochodzą z YAML, nigdy z modelu. Lokalne AI tylko przepisuje tekst dla `--friendly`.

### Funkcje AI
- `ai` / `sc` — zapytanie do mechanika
- `si` — zapytanie do mini (szybki)
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

## patterns/
**Certyfikowane wzorce diagnostyczne.** Baza YAML znanych wzorców awarii z bezpiecznymi procedurami naprawczymi.

- `common.yaml` — 5 certyfikowanych wzorców:
  - Qt6 + Wayland tray crash (`arch-update-tray`)
  - NVIDIA zawieszenie po suspendzie (`nvidia-modeset`)
  - Awaria usług portalowych (`xdg-desktop-portal`)
  - WirePlumber / PipeWire awaria audio
  - Brak pamięci (OOM killer)
- `matcher.py` — Python 3 + PyYAML silnik scoringowy:
  - trafienie service: +5
  - trafienie exe: +4
  - trafienie signal: +3
  - trafienie error: +3
  - bonus multi-hit: +2 za każdy dodatkowy typ trafienia
  - próg: score ≥ 4

**Struktura:** Każdy wzorzec zawiera `explanation`, `impact`, `recommended_action`, `risk`, `rollback`, `alternative`, `references` oraz poziom `confidence` (`certified`/`community`/`ai_suggestion`). Społeczność może dodawać nowe wzorce przez PR.
