#!/bin/bash

# Shared helper functions for installer scripts.

: "${APT_UPDATE_SENTINEL:=/tmp/dotfiles_apt_updated_$$}"
export APT_UPDATE_SENTINEL

# Return 0 when running inside WSL.
is_wsl() {
    grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null
}

# Clean up deprecated/broken third-party apt sources to prevent update failures.
remove_deprecated_apt_sources() {
    local charm_list="/etc/apt/sources.list.d/charm.list"
    if [ -f "$charm_list" ] && grep -q "repo.charm.sh/apt" "$charm_list"; then
        echo "Removing deprecated Charm apt source (no longer used for Glow)."
        sudo rm -f "$charm_list"
    fi
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
    remove_deprecated_apt_sources
    sudo apt-get update
    export APT_UPDATED=1
    touch "${APT_UPDATE_SENTINEL:-/tmp/dotfiles_apt_updated}"
}

# Ensure ~/.local/bin exists.
ensure_local_bin() {
    mkdir -p "$HOME/.local/bin"
}
