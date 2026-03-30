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

    # Create keyrings directory if it doesn't exist
    sudo mkdir -p /etc/apt/keyrings

    REPO_ADDED=false
    if [ ! -f /etc/apt/sources.list.d/gierens.list ]; then
        # Download and verify GPG key fingerprint before trusting the repo.
        KEY_URL="https://raw.githubusercontent.com/eza-community/eza/main/deb.asc"
        EXPECTED_FP="${EZA_KEY_FINGERPRINT:?EZA_KEY_FINGERPRINT not set – run scripts/bump-versions.sh}"
        TMP_KEY="$(mktemp /tmp/eza-key.XXXXXX.asc)"
        trap 'rm -f "$TMP_KEY"' EXIT

        curl -fLsS "$KEY_URL" -o "$TMP_KEY"
        ACTUAL_FP="$(gpg --with-colons --import-options show-only --import "$TMP_KEY" 2>/dev/null | awk -F: '/^fpr:/ {print $10; exit}')"
        if [ -z "$ACTUAL_FP" ] || [ "$ACTUAL_FP" != "$EXPECTED_FP" ]; then
            echo "Fingerprint mismatch for eza apt repo key."
            echo "Expected: $EXPECTED_FP"
            echo "Actual:   ${ACTUAL_FP:-<none>}"
            echo "Refusing to add the repository."
            exit 1
        fi

        sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg "$TMP_KEY"
        rm -f "$TMP_KEY"
        trap - EXIT

        # Add repository (use HTTPS to avoid MITM)
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] https://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
        
        # Set permissions
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
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
