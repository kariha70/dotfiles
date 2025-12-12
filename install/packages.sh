#!/bin/bash

set -e
set -o pipefail

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
        gnupg
        wakeonlan
    )

    add_first_available() {
        local label="$1"
        shift
        for pkg in "$@"; do
            if apt-cache show "$pkg" >/dev/null 2>&1; then
                PACKAGES+=("$pkg")
                return 0
            fi
        done
        echo "Skipping $label (apt package not available on this distro)"
    }

    add_optional_package() {
        local pkg="$1" label="${2:-$1}"
        add_first_available "$label" "$pkg"
    }

    # Optional modern CLI tools when available on this distro
    add_first_available "dust" du-dust dust   # package name varies by distro
    add_optional_package "procs" "procs"
    add_optional_package "gping" "gping"
    add_optional_package "hyperfine" "hyperfine"
    add_optional_package "httpie" "HTTPie"

    # Add openssh-server if not on WSL
    if ! is_wsl; then
        PACKAGES+=(openssh-server)
    fi
    
    # Filter already-installed packages for faster reruns.
    MISSING_PACKAGES=()
    for pkg in "${PACKAGES[@]}"; do
        if dpkg -s "$pkg" >/dev/null 2>&1; then
            continue
        fi
        MISSING_PACKAGES+=("$pkg")
    done

    if [ "${#MISSING_PACKAGES[@]}" -gt 0 ]; then
        sudo apt-get install -y --no-install-recommends "${MISSING_PACKAGES[@]}"
    else
        echo "All requested packages already installed."
    fi

    # Ensure libsecret credential helper for Git on non-WSL installs
    if ! is_wsl; then
        if ! command -v git-credential-libsecret >/dev/null 2>&1; then
            if ! sudo apt-get install -y git-credential-libsecret 2>/dev/null; then
                echo "git-credential-libsecret package not available; attempting to build from git contrib."
                sudo apt-get install -y libsecret-1-0 libsecret-1-dev
                HELPER_SRC="/usr/share/doc/git/contrib/credential/libsecret"
                if [ -d "$HELPER_SRC" ]; then
                    (cd "$HELPER_SRC" && sudo make && sudo install git-credential-libsecret /usr/local/bin/)
                else
                    echo "libsecret helper source not found at $HELPER_SRC; skipping helper build."
                fi
            fi
        fi
    fi
else
    echo "Package manager not supported in this script yet. Please install 'stow' manually."
fi

echo "Package installation complete."
