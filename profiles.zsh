#!/usr/bin/env zsh
# ===============================================================
# SysQCLI Config v1.0 — PROFILES (Host Detection)
# ===============================================================

local host=$(hostname)

case "$host" in
    sysqcli*|laptop*|SysQ*)
        export SYSCLI_PROFILE="laptop"
        export SYSCLI_POWER="normal"
        ;;
    desktop*|ws*)
        export SYSCLI_PROFILE="desktop"
        export SYSCLI_POWER="performance"
        ;;
    *)
        export SYSCLI_PROFILE="generic"
        export SYSCLI_POWER="balanced"
        ;;
esac
