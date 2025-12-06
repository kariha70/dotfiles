#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HELPERS="$SCRIPT_DIR/lib/helpers.sh"
if [ -f "$HELPERS" ]; then
    # shellcheck source=/dev/null
    source "$HELPERS"
fi
if ! command -v apt_update_once >/dev/null 2>&1; then
    apt_update_once() { sudo apt-get update; }
fi

echo "Installing zoxide..."

if command -v zoxide &> /dev/null; then
    echo "zoxide is already installed."
    exit 0
fi

# Prefer apt on Debian/Ubuntu (keeps updates via apt upgrade)
if command -v apt-get &> /dev/null; then
    apt_update_once
    if sudo apt-get install -y zoxide; then
        echo "zoxide installed via apt."
        exit 0
    fi
    echo "apt installation failed, falling back to upstream installer."
fi

# Fallback: install zoxide to ~/.local/bin with checksum enforcement
INSTALLER_PATH=/tmp/zoxide-install.sh
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh -o "$INSTALLER_PATH"
ACTUAL_SHA=$(sha256sum "$INSTALLER_PATH" | awk '{print $1}')
if [ -z "${ZOXIDE_INSTALLER_SHA256:-}" ]; then
    echo "Installer SHA256: $ACTUAL_SHA"
    echo "Set ZOXIDE_INSTALLER_SHA256 to the value above to proceed (aborting to avoid running an unverified installer)."
    exit 1
fi
if [ "$ACTUAL_SHA" != "$ZOXIDE_INSTALLER_SHA256" ]; then
    echo "Checksum mismatch for zoxide installer."
    echo "Expected: $ZOXIDE_INSTALLER_SHA256"
    echo "Actual:   $ACTUAL_SHA"
    exit 1
fi
bash "$INSTALLER_PATH"
rm -f "$INSTALLER_PATH"

echo "zoxide installed."
