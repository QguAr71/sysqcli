# SysQCLI — BLUEPRINT

**Stan:** v1.1 — feature-complete, stabilna  
**Repo:** https://github.com/QguAr71/sysqcli  
**Cel długoterminowy:** stać się *de facto* referencyjnym configiem ZSH dla świadomych użytkowników Linuksa. Nie konkurować z Oh-My-Zsh ilością pluginów — wygrywać bezpieczeństwem, modularnością i rozsądkiem.

---

## v1.1 — STAN OBECNY ✅

```
15 modułów | rollback + integrity + 3 tryby + thermal autopilot + AI + guard
```

| Feature | Status |
|---------|--------|
| Rollback snapshotów (GC max 10) | ✅ |
| Integrity SHA256 (qsign/qverify) | ✅ |
| Tryby: safe / immutable / full | ✅ |
| Thermal autopilot 83°C | ✅ |
| Security Guard (blokada rm -rf /, mkfs, dd...) | ✅ |
| AI Ollama (profile: mini/normal/mechanik) | ✅ |
| fkill, qhealth, btop | ✅ |
| CI GitHub Actions (zsh -n) | ✅ |
| ~/.sysqclirc (user config) | ✅ |
| curl \| sh installer + --dry-run + --uninstall | ✅ |
| Demo GIF | ✅ |
| EN docs + PL translations | ✅ |

---

## v1.2 — STABILIZACJA I TESTY

### Cel
Nic nowego nie dodajemy. Tylko testy, bugfixy, CI rozbudowane.

### Zadania
- [ ] **Testy integracyjne** — osobny skrypt który sprawdza:
  - Czy `init.zsh` ładuje wszystkie moduły w full mode
  - Czy safe mode ładuje tylko core + aliases + audit
  - Czy immutable mode robi `qverify` + `chattr +i`
  - Czy `qcheck_deps` poprawnie wykrywa brakujące pakiety
- [ ] **CI rozszerzone** — GitHub Actions:
  - Test integracyjny na Ubuntu (sprawdza czy init.zsh się nie wysypuje)
  - `shellcheck` na skrypcie instalatora
  - Check czy zmienne środowiskowe nie wyciekają
- [ ] **Bugfixy** — przejrzeć issues (jeśli będą), poprawić znalezione błędy
- [ ] **Test manualny na Ubuntu** — czy instalator działa poza Archem (tylko instalacja, bez paczek)

### Nie robimy
- ❌ Nowych funkcji
- ❌ Refaktora architektury

---

## v2.0 — MULTI-DISTRO + WIELOJĘZYCZNOŚĆ

### Cel
SysQCLI działa na Ubuntu, Fedorze, Voidzie. AI mówi w języku użytkownika.

### 2.1 qpkg multi-distro
- [ ] `qpkg` wykrywa i obsługuje:
  - `apt` (Ubuntu/Debian)
  - `dnf` (Fedora)
  - `xbps` (Void)
  - `zypper` (openSUSE) — nice to have
- [ ] `qinstall` instaluje pakiety odpowiednie dla distro
- [ ] `up` używa `qpkg upgrade` zamiast hardcodowanego pacmana
- [ ] `clean` używa `qpkg clean`
- [ ] Test na min. 3 dystrybucjach (GitHub Actions matrix)

### 2.2 AI prompt auto-detekcja języka
- [ ] Prompt systemowy wykrywa `$LANG` i dostosowuje język:
  - `pl_PL*` → po polsku
  - Wszystko inne → po angielsku
- [ ] Opcja override: `SYSCLI_AI_LANG="pl"` w `~/.sysqclirc`
- [ ] Angielski prompt systemowy: "You are an Arch Linux terminal expert. Answer concisely and technically."

### 2.3 Drobne usprawnienia
- [ ] `install.sh` — wykrywa distro przy instalacji, daje odpowiednie instrukcje
- [ ] `docs/INSTALL.md` — instrukcje per distro
- [ ] `qcheck_deps` — mapowanie nazw pakietów per distro (np. `bat` vs `batcat` na Ubuntu)

---

## v2.1 — PLUGIN SYSTEM

### Cel
Użytkownik może dodawać własne moduły bez edycji `init.zsh`.

### Zadania
- [ ] Katalog `~/.config/sysqcli/plugins.d/` — auto-loaded
  - Każdy plik `*.zsh` w tym katalogu jest source'owany po aliases.zsh
  - Kolejność alfabetyczna (jak `.d/` w systemd)
- [ ] `SysQCLI_NO_PLUGINS=1` w `~/.sysqclirc` wyłącza auto-loading
- [ ] Przykładowy plugin w repo: `plugins.d/example.zsh`
- [ ] Dokumentacja: `docs/PLUGINS.md` — jak pisać pluginy

---

## v2.2 — INSTALATOR WWW + STATYSTYKI (nice to have)

### Cel
Jednostronicowa strona instalacyjna + anonimowe statystyki adopcji.

### Zadania
- [ ] `get.sysqcli.sh` — krótki URL przekierowujący do instalatora
- [ ] Strona `sysqcli.dev` (GitHub Pages):
  - Demo GIF
  - One-liner instalacyjny
  - Porównanie z Oh-My-Zsh / Zinit / Zim
- [ ] Opcjonalny telemetry ping przy instalacji (tylko `distro + version`, bez danych osobowych)
  - `curl -s -o /dev/null "https://sysqcli.dev/ping?distro=arch&v=2.0"`
  - Można wyłączyć: `SYSCLI_NO_TELEMETRY=1`

---

## v3.0 — BEYOND ZSH (odległa przyszłość)

### Cel
SysQCLI jako platforma, nie tylko config. Wykracza poza ZSH.

### Potencjalne kierunki
- [ ] **SysQCLI dla Basha** — uproszczona wersja modułów (rollback, integrity, guard) działająca w bash
- [ ] **SysQCLI dla Fish** — adaptacja do fish shell
- [ ] **TUI konfigurator** — `sysqcli-tui` — terminalowy interfejs do zarządzania modułami, podgląd snapshotów, podpisywanie
- [ ] **Sync przez GitHub Gist** — backup configu do gista (opcjonalnie, zaszyfrowane)
- [ ] **Web dashboard** — własny dashboard (nie tak absurdalny jak w layered-zsh 😂) pokazujący stan configu, snapshoty, integrity

### Na razie NIE robimy
- ❌ Instalator GUI
- ❌ Mobile app (layered-zsh już to wyśmiał)
- ❌ Microservices (serio, do shella?)

---

## 📊 Priorytety

| Wersja | Czas realizacji | Wpływ |
|--------|-----------------|-------|
| **v1.2** — testy, CI | 2-3h | Stabilność, zaufanie użytkowników |
| **v2.0** — multi-distro + język | 4-6h | 🔥 Rozszerza bazę użytkowników z "tylko Arch" na "każdy Linux" |
| **v2.1** — plugin system | 1-2h | Elastyczność, ekosystem |
| **v2.2** — strona www | 3-4h | Marketing, adopcja |
| **v3.0** — TUI, sync, dashboard | ∞ | Długoterminowa wizja |

---

## 🎯 Co NIE wchodzi do SysQCLI (świadome decyzje)

| Feature | Dlaczego NIE |
|---------|-------------|
| Pacman wrapper z `--noconfirm` | Niebezpieczne. `up` pyta przed instalacją. |
| Własny HUD | btop jest lepszy. Nie konkurujemy. |
| setopt'y history (HIST_IGNORE_DUPS itp.) | To należy do użytkownika, nie do platformy. |
| Auto-update configu | użytkownik powinien świadomie aktualizować. `git pull` wystarczy. |
| Oh-My-Zsh / Prezto | SysQCLI jest alternatywą, nie wrapperem. |
| Prompt | p10k to wystarczy. SysQCLI nie będzie siódmym frameworkiem do promptów. |

---

## 📝 Zasady rozwoju

1. **Każda zmiana = osobny commit** z czytelnym opisem (już tak robimy ✅)
2. **Moduł musi działać samodzielnie** — użytkownik może wziąć TYLKO `rollback.zsh` i używać go bez reszty
3. **Zero ukrytych zależności** — jeśli moduł wymaga zewnętrznego narzędzia, sprawdza czy istnieje i degraduje się
4. **Dokumentacja przed kodem** — najpierw `docs/`, potem implementacja
5. **EN primary** — wszystkie nowe docs po angielsku, PL jako tłumaczenie

---

> *"This started as a .zshrc. Now it has a blueprint, CI, and a roadmap."*
> — SysQCLI Team, 2026
