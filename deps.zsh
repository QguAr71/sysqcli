#!/usr/bin/env zsh
# ===============================================================
# SysQCLI Config v1.0 — DEPS (Dependency Check + qinstall)
# ===============================================================

qcheck_deps() {
    local missing=()
    command -v fzf       &>/dev/null || missing+=("fzf")
    command -v zoxide    &>/dev/null || missing+=("zoxide")
    command -v micro     &>/dev/null || missing+=("micro")
    command -v bat       &>/dev/null || missing+=("bat")
    command -v lsd       &>/dev/null || missing+=("lsd")
    command -v fastfetch &>/dev/null || missing+=("fastfetch")
    command -v rg        &>/dev/null || missing+=("ripgrep")
    command -v fd        &>/dev/null || missing+=("fd")
    command -v ollama    &>/dev/null || missing+=("ollama")
    command -v grc       &>/dev/null || missing+=("grc")

    [[ ${#missing[@]} -gt 0 ]] && {
        echo -e "\e[33m SysQCLI: brakuje: ${missing[*]}\e[0m"
        echo -e "\e[33m   Wpisz \e[1m'qinstall'\e[0m\e[33m aby zainstalować.\e[0m"
    }
}

qinstall() {
    local pacman_pkgs=()
    command -v fzf       &>/dev/null || pacman_pkgs+=(fzf)
    command -v zoxide    &>/dev/null || pacman_pkgs+=(zoxide)
    command -v micro     &>/dev/null || pacman_pkgs+=(micro)
    command -v bat       &>/dev/null || pacman_pkgs+=(bat)
    command -v lsd       &>/dev/null || pacman_pkgs+=(lsd)
    command -v fastfetch &>/dev/null || pacman_pkgs+=(fastfetch)
    command -v rg        &>/dev/null || pacman_pkgs+=(ripgrep)
    command -v fd        &>/dev/null || pacman_pkgs+=(fd)
    command -v ollama    &>/dev/null || pacman_pkgs+=(ollama)
    command -v grc       &>/dev/null || pacman_pkgs+=(grc)

    local aur_pkgs=()
    # zinit detection
    [[ -f "$HOME/.local/share/zinit/zinit.git/zinit.zsh" ]] || aur_pkgs+=("zinit (AUR: zinit-git)")
    [[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] || aur_pkgs+=("zsh-autosuggestions")

    [[ ${#pacman_pkgs[@]} -gt 0 ]] && sudo pacman -S --needed "${pacman_pkgs[@]}"
    [[ ${#aur_pkgs[@]} -gt 0 ]] && echo -e "\e[36m AUR (zainstaluj ręcznie): ${aur_pkgs[*]}\e[0m"

    echo -e "\e[32m qinstall zakończone.\e[0m"
}
