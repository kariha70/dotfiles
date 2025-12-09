#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HELPERS="$SCRIPT_DIR/lib/helpers.sh"
if [ -f "$HELPERS" ]; then
    # shellcheck source=/dev/null
    source "$HELPERS"
fi
VERSIONS_FILE="${VERSIONS_FILE:-$SCRIPT_DIR/versions.env}"
if [ -f "$VERSIONS_FILE" ]; then
    # shellcheck source=/dev/null
    source "$VERSIONS_FILE"
else
    echo "versions.env not found at $VERSIONS_FILE. Run scripts/bump-versions.sh to generate it."
    exit 1
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
EXPECTED_ZOXIDE_SHA="${ZOXIDE_INSTALLER_SHA256:-}"
if [ -z "$EXPECTED_ZOXIDE_SHA" ]; then
    echo "ZOXIDE_INSTALLER_SHA256 missing. Run scripts/bump-versions.sh to refresh install/versions.env."
    rm -f "$INSTALLER_PATH"
    exit 1
fi
if [ "$ACTUAL_SHA" != "$EXPECTED_ZOXIDE_SHA" ]; then
    echo "Checksum mismatch for zoxide installer."
    echo "Expected: $EXPECTED_ZOXIDE_SHA"
    echo "Actual:   $ACTUAL_SHA"
    echo "Update install/versions.env with scripts/bump-versions.sh if a new release is available."
    rm -f "$INSTALLER_PATH"
    exit 1
fi
bash "$INSTALLER_PATH"
rm -f "$INSTALLER_PATH"

echo "zoxide installed."
