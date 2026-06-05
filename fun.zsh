#!/usr/bin/env zsh
# ===============================================================
# SysQCLI Config v1.0 — FUN (Lightweight humor/utility)
# ===============================================================

# Pogoda
alias pogodynka='curl -s "wttr.in/Warszawa?m&format=v2" 2>/dev/null | bat --paging=never --file-name="SysQCLI WEATHER" 2>/dev/null || curl -s "wttr.in/Warszawa?m&format=v2"'
