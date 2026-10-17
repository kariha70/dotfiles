#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"
source_versions "$SCRIPT_DIR"

echo "Installing eza..."

if is_macos; then
    echo "macOS detected. eza is managed via Homebrew (install/Brewfile)."
    exit 0
fi

# Check if eza is already installed
if command -v eza &> /dev/null; then
    echo "eza is already installed."
    exit 0
fi

# Check for apt-get (Debian/Ubuntu)
if command -v apt-get &> /dev/null; then
    echo "Detected apt-get. Setting up eza repository..."

    # Ensure gpg is available for key verification (packages.sh installs gnupg).
    if ! command -v gpg >/dev/null 2>&1; then
        apt_update_once
        sudo apt-get install -y gnupg
    fi

    KEYRING="/etc/apt/keyrings/gierens.gpg"
    TMP_KEYRING="$(mktemp /tmp/eza-keyring.XXXXXX.gpg)"
    trap 'rm -f "$TMP_KEYRING"' EXIT
    fetch_apt_key "https://raw.githubusercontent.com/eza-community/eza/main/deb.asc" \
        "${EZA_KEY_FINGERPRINT:-}" "$TMP_KEYRING"
    install_apt_source "$TMP_KEYRING" "$KEYRING" /etc/apt/sources.list.d/gierens.list \
        "deb [signed-by=$KEYRING] https://deb.gierens.de stable main"
    if [ "$APT_SOURCE_CHANGED" = "1" ]; then
        apt_update_force
    else
        apt_update_once
    fi
    sudo apt-get install -y eza
    
    echo "eza installed successfully."
elif command -v pacman >/dev/null 2>&1; then
    echo "Detected pacman. Installing eza from the Arch Linux repositories..."
    pacman_install eza
    echo "eza installed successfully."
else
    echo "Package manager not supported for automatic eza installation. Please install eza manually."
fi
