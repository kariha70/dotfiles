#!/bin/bash

set -e

echo "Installing packages..."

# Check for apt-get (Debian/Ubuntu)
if command -v apt-get &> /dev/null; then
    echo "Detected apt-get. Updating and installing packages..."
    sudo apt-get update
    
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
        tldr
        btop
        tmux
        git-delta
    )

    # Add openssh-server if not on WSL
    if ! grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
        PACKAGES+=(openssh-server)
    fi
    
    sudo apt-get install -y "${PACKAGES[@]}"
else
    echo "Package manager not supported in this script yet. Please install 'stow' manually."
fi

echo "Package installation complete."
