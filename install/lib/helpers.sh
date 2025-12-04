#!/bin/bash

# Shared helper functions for installer scripts.

# Return 0 when running inside WSL.
is_wsl() {
    grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null
}

# Run apt-get update only once per script invocation.
apt_update_once() {
    if ! command -v apt-get >/dev/null; then
        return 1
    fi
    if [ -n "${APT_UPDATED:-}" ]; then
        echo "Skipping apt-get update (already run in this script)."
        return 0
    fi
    echo "Updating apt package index..."
    sudo apt-get update
    APT_UPDATED=1
}

# Ensure ~/.local/bin exists.
ensure_local_bin() {
    mkdir -p "$HOME/.local/bin"
}
