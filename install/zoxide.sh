#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"
source_versions "$SCRIPT_DIR"

echo "Installing zoxide..."

if is_macos; then
    echo "macOS detected. zoxide is managed via Homebrew (install/Brewfile)."
    exit 0
fi

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
curl -fLsS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh -o "$INSTALLER_PATH"
EXPECTED_ZOXIDE_SHA="${ZOXIDE_INSTALLER_SHA256:-}"
verify_sha256 "$INSTALLER_PATH" "$EXPECTED_ZOXIDE_SHA" "zoxide installer"
bash "$INSTALLER_PATH"

echo "zoxide installed."
