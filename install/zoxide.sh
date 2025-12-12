#!/bin/bash

set -e
set -o pipefail

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
INSTALLER_PATH="$(mktemp /tmp/zoxide-install.XXXXXX.sh)"
trap 'rm -f "$INSTALLER_PATH"' EXIT
curl -fsS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh -o "$INSTALLER_PATH"
EXPECTED_ZOXIDE_SHA="${ZOXIDE_INSTALLER_SHA256:-}"
verify_sha256 "$INSTALLER_PATH" "$EXPECTED_ZOXIDE_SHA" "zoxide installer"
bash "$INSTALLER_PATH"

echo "zoxide installed."
