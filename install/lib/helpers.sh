#!/bin/bash

# Shared helper functions for installer scripts.

: "${APT_UPDATE_SENTINEL:=/tmp/dotfiles_apt_updated_$$}"
export APT_UPDATE_SENTINEL

# Return 0 when running inside WSL.
is_wsl() {
    grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null
}

# Run apt-get update only once per script invocation.
apt_update_once() {
    if ! command -v apt-get >/dev/null; then
        return 1
    fi
    if [ "${1:-}" = "--force" ]; then
        shift
    elif [ -n "${APT_UPDATED:-}" ] || [ -f "${APT_UPDATE_SENTINEL:-/tmp/dotfiles_apt_updated}" ]; then
        echo "Skipping apt-get update (already run)."
        return 0
    fi
    echo "Updating apt package index..."
    sudo apt-get update
    export APT_UPDATED=1
    touch "${APT_UPDATE_SENTINEL:-/tmp/dotfiles_apt_updated}"
}

# Ensure ~/.local/bin exists.
ensure_local_bin() {
    mkdir -p "$HOME/.local/bin"
}
