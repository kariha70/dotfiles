#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"
source_versions "$SCRIPT_DIR"

echo "Installing bun..."

if is_macos; then
    echo "macOS detected. bun is managed via Homebrew (install/Brewfile)."
    exit 0
fi

if command -v bun &> /dev/null; then
    echo "bun is already installed."
    exit 0
fi

EXPECTED_SHA="${BUN_INSTALLER_SHA256:-}"
INSTALLER_PATH="$(mktemp /tmp/bun-install.XXXXXX.sh)"
trap 'rm -f "$INSTALLER_PATH"' EXIT
download_and_verify "https://bun.sh/install" "$INSTALLER_PATH" "$EXPECTED_SHA" "bun installer"

# Override SHELL so the installer skips modifying shell profiles
# (we manage .bashrc/.zshrc via stow).
SHELL=/bin/sh bash "$INSTALLER_PATH"

echo "bun installed successfully."
