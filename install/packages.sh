#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HELPERS="$SCRIPT_DIR/lib/helpers.sh"
if [ -f "$HELPERS" ]; then
    # shellcheck source=/dev/null
    source "$HELPERS"
fi
if ! command -v is_wsl >/dev/null 2>&1; then
    is_wsl() { grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; }
fi
if ! command -v apt_update_once >/dev/null 2>&1; then
    apt_update_once() { sudo apt-get update; }
fi

echo "Installing packages..."

# Check for apt-get (Debian/Ubuntu)
if command -v apt-get &> /dev/null; then
    echo "Detected apt-get. Updating and installing packages..."
    apt_update_once
    
    # List of packages to install
    PACKAGES=(
        curl
        git
        vim
        stow
        htop
        jq
        build-essential
        zsh
        fontconfig
        fzf
        bat
        ripgrep
        fd-find
        tealdeer   # provides the `tldr` command
        btop
        tmux
        neovim
        unzip
        shellcheck
    )

    # Add openssh-server if not on WSL
    if ! is_wsl; then
        PACKAGES+=(openssh-server)
    fi
    
    sudo apt-get install -y "${PACKAGES[@]}"
else
    echo "Package manager not supported in this script yet. Please install 'stow' manually."
fi

echo "Package installation complete."
