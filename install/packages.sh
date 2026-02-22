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
if ! command -v is_macos >/dev/null 2>&1; then
    is_macos() { [ "$(uname -s)" = "Darwin" ]; }
fi
if ! command -v apt_update_once >/dev/null 2>&1; then
    apt_update_once() { sudo apt-get update; }
fi

echo "Installing packages..."

if is_macos; then
    echo "macOS detected. Package installation is handled by install/macos.sh."
    exit 0
fi

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
    PROCS_APT_AVAILABLE=0

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
    if apt-cache show procs >/dev/null 2>&1; then
        PACKAGES+=(procs)
        PROCS_APT_AVAILABLE=1
    else
        echo "procs not available via apt; will try cargo fallback."
    fi
    add_optional_package "gping" "gping"
    add_optional_package "hyperfine" "hyperfine"
    add_optional_package "httpie" "HTTPie"
    add_optional_package "just" "just"
    add_optional_package "xh" "xh"
    add_optional_package "bottom" "bottom"

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

    # Fallback for procs when apt package is unavailable on this distro/WSL image.
    if ! command -v procs >/dev/null 2>&1 && [ "$PROCS_APT_AVAILABLE" -eq 0 ]; then
        echo "Attempting procs install via cargo fallback..."

        if ! command -v cargo >/dev/null 2>&1; then
            if apt-cache show cargo >/dev/null 2>&1; then
                apt_update_once
                sudo apt-get install -y cargo
            else
                echo "Skipping procs fallback (cargo package not available)."
            fi
        fi

        if command -v cargo >/dev/null 2>&1; then
            if command -v ensure_local_bin >/dev/null 2>&1; then
                ensure_local_bin
            else
                mkdir -p "$HOME/.local/bin"
            fi

            if cargo install --locked --root "$HOME/.local" procs; then
                echo "procs installed via cargo fallback."
            else
                echo "procs cargo fallback failed; continuing without procs."
            fi
        fi
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
