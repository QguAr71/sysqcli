#!/usr/bin/env zsh
# ===============================================================
# SysQCLI Config v1.0 — HELP (sysqcli + F1)
# ===============================================================

sysqcli() {
    clear
    echo -e "\e[1;35m         ◢◤ SysQCLI v$SYSCLI_VERSION — SYSTEM DOWODZENIA ◢◤\e[0m"
    echo -e "\e[1;33mUżytkownik: $USER | Profil: $SYSCLI_PROFILE | Tryb: $SYSCLI_MODE | PM: $SYSCLI_PM\e[0m"
    echo -e "─────────────────────────────────────────────────────────────"
    echo -e "\e[1;34m🤖 AI & DIAGNOSTYKA:\e[0m"
    echo -e "  \e[1;32msc/si/sii\e[0m       - Asystent AI (DeepSeek / Phi3 / Llama 3)"
    echo -e "  \e[1;32mfix\e[0m            - AI analizuje błędy z journalctl i naprawia"
    echo -e "  \e[1;32msummary\e[0m        - AI podsumowuje Twój dzień w terminalu"
    echo -e "\n\e[1;34m🛡️ OCHRONA & ROLLBACK:\e[0m"
    echo -e "  \e[1;32mqsafe/qunsafe\e[0m  - Przełącz tryb awaryjny"
    echo -e "  \e[1;32mqimm/qfull\e[0m     - Immutable / Full mode"
    echo -e "  \e[1;32mqsign/qverify\e[0m  - Podpisz / Zweryfikuj integralność configu"
    echo -e "  \e[1;32mqrestore\e[0m       - Przywróć ostatni snapshot"
    echo -e "  \e[1;32mqsnaps\e[0m         - Lista snapshotów"
    echo -e "\n\e[1;34m📦 SYSTEM:\e[0m"
    echo -e "  \e[1;32mup\e[0m             - SUPER UPDATE: System + AUR + AI + clean"
    echo -e "  \e[1;32mqupdate\e[0m        - Tylko aktualizacja pacman (bez AI modeli)"
    echo -e "  \e[1;32mclean\e[0m          - Sprzątanie cache, logów, RAM"
    echo -e "  \e[1;32mturbo / eco\e[0m    - Ręczne przełączanie profilu CPU"
    echo -e "  \e[1;32mqhealth\e[0m        - Diagnostyka: temp, RAM, dysk, coredumpy"
    echo -e "  \e[1;32mqtop\e[0m           - btop (monitoring systemu)"
    echo -e "  \e[1;32mhud\e[0m            - SysQCLI HUD na żywo (temp, CPU, RAM)"
    echo -e "  \e[1;32mqinstall\e[0m       - Zainstaluj brakujące zależności"
    echo -e "\n\e[1;34m📂 NAWIGACJA:\e[0m"
    echo -e "  \e[1;32mzi\e[0m             - Skoki Zoxide + FZF"
    echo -e "  \e[1;32mfn [tekst]\e[0m     - Szukaj frazy w plikach → edytor"
    echo -e "  \e[1;32mfp\e[0m             - Przeglądaj pliki FZF z podglądem"
    echo -e "  \e[1;32mfedit\e[0m           - Wybierz i edytuj plik przez FZF"
    echo -e "  \e[1;32mfkill\e[0m           - Zabij proces przez FZF"
    echo -e "  \e[1;32my\e[0m              - Yazi (file manager)"
    echo -e "  \e[1;32mex [plik]\e[0m      - Smart Extract + pytanie o usunięcie"
    echo -e "\n\e[1;34m🌐 SZYBKIE WYSZUKIWANIE:\e[0m"
    echo -e "  \e[1;32mwiki [hasło]\e[0m   - Arch Wiki"
    echo -e "  \e[1;32mgoogle [hasło]\e[0m - Google"
    echo -e "  \e[1;32mgithub [hasło]\e[0m - GitHub"
    echo -e "\n\e[1;34m⚡ ALIASY GLOBALNE (na końcu ksysqclidy):\e[0m"
    echo -e "  \e[1;32mG\e[0m (Grep) | \e[1;32mL\e[0m (Less) | \e[1;32mM\e[0m (Micro) | \e[1;32mNE\e[0m (Ukryj błędy)"
    echo -e "─────────────────────────────────────────────────────────────"
    echo -e "\e[1;33mSystem gotowy. F1 = ta pomoc.\e[0m"
}

# F1 → sysqcli
bindkey -s '^[OP' 'sysqcli\n' 2>/dev/null
bindkey -s '^[[[A' 'sysqcli\n' 2>/dev/null
