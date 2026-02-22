#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HELPERS="$SCRIPT_DIR/lib/helpers.sh"
if [ -f "$HELPERS" ]; then
    # shellcheck source=/dev/null
    source "$HELPERS"
fi
if ! command -v is_macos >/dev/null 2>&1; then
    is_macos() { [ "$(uname -s)" = "Darwin" ]; }
fi

is_true() {
    case "${1:-}" in
        1|true|TRUE|yes|YES|y|Y|on|ON) return 0 ;;
        *) return 1 ;;
    esac
}

if ! is_macos; then
    echo "Not running on macOS. Skipping macOS package setup."
    exit 0
fi

if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required for macOS setup but was not found."
    echo "Install Homebrew from https://brew.sh and rerun ./bootstrap.sh."
    exit 1
fi

BREWFILE_PATH="${BREWFILE_PATH:-$SCRIPT_DIR/Brewfile}"
if [ ! -f "$BREWFILE_PATH" ]; then
    echo "Brewfile not found at $BREWFILE_PATH"
    exit 1
fi

echo "Updating Homebrew..."
brew update

echo "Installing macOS packages from Brewfile..."
brew bundle --file "$BREWFILE_PATH" --no-upgrade

if is_true "${BREW_CLEANUP:-0}"; then
    echo "Cleaning packages not listed in Brewfile..."
    brew bundle cleanup --file "$BREWFILE_PATH" --force
fi

echo "macOS package installation complete."
