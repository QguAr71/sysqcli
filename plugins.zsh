#!/usr/bin/env zsh
# ===============================================================
# SysQCLI Config v1.0 — PLUGINS (zinit + p10k + system plugins)
# ===============================================================

# --- Powerlevel10k (z systemu lub z zinit) ---
if [[ -f /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme ]]; then
    source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
elif [[ -f "$HOME/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
    source "$HOME/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme"
fi

# --- System plugins (CachyOS/Arch paths) ---
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh ]] && \
    source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#928374,italic"

# --- Syntax highlighting — Frosted Mint ---
if command -v fast-syntax-highlighting-config &>/dev/null; then
    fast-syntax-highlighting-config --set-face main 'fg=#a597d2' 2>/dev/null
    fast-syntax-highlighting-config --set-face path 'fg=#8ec07c' 2>/dev/null
else
    zstyle ':fast-syntax-highlighting' 'main' 'fg=#a597d2'
    zstyle ':fast-syntax-highlighting' 'path' 'fg=#8ec07c'
fi
zstyle ':fast-syntax-highlighting' 'string' 'fg=#83a598'

# --- Completion ---
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*:*:*:*:titles' format '%F{#83a598}── %d ──%f'

# --- GRC ---
[[ -f /etc/grc.zsh ]] && source /etc/grc.zsh

# --- Atuin + Zoxide ---
command -v atuin  &>/dev/null && eval "$(atuin init zsh)"
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# --- Kitty completion ---
[[ "$TERM" == "xterm-kitty" ]] && kitty +complete setup zsh 2>/dev/null | source /dev/stdin 2>/dev/null

# --- p10k config ---
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
