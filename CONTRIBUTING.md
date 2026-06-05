# Contributing to SysQCLI

## Architektura

SysQCLI jest **modularna** — każdy plik `.zsh` to osobny moduł z jedną odpowiedzialnością.

```
init.zsh           # Entry point — nie edytuj bez potrzeby
├── rollback.zsh   # Snapshot + restore
├── profiles.zsh   # Host detection
├── core.zsh       # Environment variables
├── deps.zsh       # Dependency checking
├── qpkg.zsh       # Package manager abstraction
├── integrity.zsh  # SHA256 signing
├── help.zsh       # Help center (sysqcli function)
├── audit.zsh      # preexec/precmd hooks
├── plugins.zsh    # ZSH plugins (p10k, syntax highlighting)
├── visuals.zsh    # Fastfetch + MOTD
├── ai.zsh         # Ollama integration
├── monitor.zsh    # HUD + fkill + qhealth
├── aliases.zsh    # Command aliases
└── fun.zsh        # Non-essential utilities
```

## Konwencje

### Zmienne systemowe
- **Prefix `SYSCLI_*`** — eksportowane, używane przez wiele modułów
- **Lokalne** — `local` wewnątrz funkcji

### Nazewnictwo funkcji
- `q*` — komendy użytkownika (`qsign`, `qverify`, `qhealth`)
- `_q*` — funkcje wewnętrzne (`_qpkg_detect`, `_ai_cache_valid`)
- `_*` — helpery wewnętrzne

### Styl
- 80 kolumn gdzie się da
- Komentarze `# --- Sekcja ---` dla grup
- Angielskie komentarze w kodzie, polskie komunikaty dla użytkownika

## Dodawanie nowego modułu

1. Stwórz plik `nazwa.zsh` w katalogu głównym
2. Dodaj `source "$SYSCLI_ROOT/nazwa.zsh"` w `init.zsh` w odpowiedniej sekcji
3. Opisz w `README.md`

## Testowanie

```bash
# Składnia
zsh -n nowy_modul.zsh

# Pełny test
exec zsh  # przeładuje SysQCLI
```

## Przyszłe kierunki

- [ ] v2: multi-distro (apt, dnf, xbps) w `qpkg.zsh`
- [ ] Testy automatyczne (CI z `zsh -n`)
- [ ] Instalator (`curl | sh`)
