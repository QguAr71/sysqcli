#!/usr/bin/env zsh
# ===============================================================
# SysQCLI Config v1.0 — CORE (Environment, PATH, Colors)
# ===============================================================

# Terminal
export TERM="${TERM:-xterm-kitty}"
export COLORTERM="truecolor"

# Editor
export EDITOR="micro"
export VISUAL="micro"
export MICRO_TRUECOLOR=1

# Style
export BAT_THEME="gruvbox-dark"
export RUSTFLAGS="-C target-cpu=native"

# PATH
export PATH="$HOME/bin:/usr/local/bin:$HOME/.cargo/bin:$SYSCLI_ROOT/scripts:$PATH"

# FZF — SysQCLI Frosted Mint color scheme
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git --exclude .cache'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--color=bg+:#3c3836,bg:-1,spinner:#fe8019,hl:#83a598,fg:#ebdbb2,header:#83a598,info:#8ec07c,pointer:#a597d2,marker:#a597d2,fg+:#ebdbb2,prompt:#a597d2,hl+:#8ec07c,border:#504945 --inline-info --border=rounded --margin=1 --padding=1"
