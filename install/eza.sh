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
    SOURCE_FILE="/etc/apt/sources.list.d/gierens.list"
    APT_SOURCE="deb [signed-by=$KEYRING] https://deb.gierens.de stable main"
    EXPECTED_FP="${EZA_KEY_FINGERPRINT:?EZA_KEY_FINGERPRINT not set - run scripts/bump-versions.sh}"
    INSTALLED_FP=""
    if [ -f "$KEYRING" ]; then
        INSTALLED_FP="$(gpg --batch --with-colons --show-keys "$KEYRING" 2>/dev/null | awk -F: '/^fpr:/ { print $10; exit }')"
    fi

    REPO_ADDED=false
    if [ "$INSTALLED_FP" != "$EXPECTED_FP" ] || [ ! -f "$SOURCE_FILE" ] || [ "$(cat "$SOURCE_FILE")" != "$APT_SOURCE" ]; then
        KEY_URL="https://raw.githubusercontent.com/eza-community/eza/main/deb.asc"
        TMP_KEY="$(mktemp /tmp/eza-key.XXXXXX.asc)"
        TMP_KEYRING="$(mktemp /tmp/eza-keyring.XXXXXX.gpg)"
        trap 'rm -f "$TMP_KEY" "$TMP_KEYRING"' EXIT

        curl -fLsS "$KEY_URL" -o "$TMP_KEY"
        ACTUAL_FP="$(gpg --batch --with-colons --import-options show-only --import "$TMP_KEY" 2>/dev/null | awk -F: '/^fpr:/ { print $10; exit }')"
        if [ -z "$ACTUAL_FP" ] || [ "$ACTUAL_FP" != "$EXPECTED_FP" ]; then
            echo "Fingerprint mismatch for eza apt repo key."
            echo "Expected: $EXPECTED_FP"
            echo "Actual:   ${ACTUAL_FP:-<none>}"
            echo "Refusing to add the repository."
            exit 1
        fi

        gpg --batch --yes --dearmor -o "$TMP_KEYRING" "$TMP_KEY"
        sudo install -d -m 755 /etc/apt/keyrings
        sudo install -m 644 "$TMP_KEYRING" "$KEYRING"
        printf '%s\n' "$APT_SOURCE" | sudo tee "$SOURCE_FILE" >/dev/null
        sudo chmod 644 "$SOURCE_FILE"

        rm -f "$TMP_KEY" "$TMP_KEYRING"
        trap - EXIT
        REPO_ADDED=true
    fi
    
    # Update and install
    if [ "$REPO_ADDED" = true ]; then
        apt_update_force
    else
        apt_update_once
    fi
    sudo apt-get install -y eza
    
    echo "eza installed successfully."
else
    echo "Package manager not supported for automatic eza installation. Please install eza manually."
fi
