#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"

echo "Installing GitHub CLI (gh)..."

if is_macos; then
    echo "macOS detected. gh is managed via Homebrew (install/Brewfile)."
    exit 0
fi

if command -v pacman >/dev/null 2>&1; then
    if command -v gh >/dev/null 2>&1; then
        echo "gh is already installed."
        exit 0
    fi
    pacman_install github-cli
    echo "gh installed via pacman."
    exit 0
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "Package manager not supported for automatic gh installation. Please install gh manually."
    exit 0
fi

source_versions "$SCRIPT_DIR"

# Use GitHub's official apt repository instead of the distro package, which
# lags far behind upstream. The keyring is pinned by SHA256 and fails closed.
EXPECTED_KEYRING_SHA="${GH_APT_KEYRING_SHA256:-}"
KEYRING="/etc/apt/keyrings/githubcli-archive-keyring.gpg"
SOURCE_FILE="/etc/apt/sources.list.d/github-cli.list"
APT_SOURCE="deb [arch=$(dpkg --print-architecture) signed-by=$KEYRING] https://cli.github.com/packages stable main"

TMP_KEYRING="$(mktemp /tmp/githubcli-keyring.XXXXXX.gpg)"
trap 'rm -f "$TMP_KEYRING"' EXIT

if [ -f "$KEYRING" ] && [ -n "$EXPECTED_KEYRING_SHA" ] && [ "$(sha256_file "$KEYRING")" = "$EXPECTED_KEYRING_SHA" ]; then
    cp "$KEYRING" "$TMP_KEYRING"
else
    download_and_verify \
        "https://cli.github.com/packages/githubcli-archive-keyring.gpg" \
        "$TMP_KEYRING" \
        "$EXPECTED_KEYRING_SHA" \
        "GitHub CLI apt keyring"
fi

install_apt_source "$TMP_KEYRING" "$KEYRING" "$SOURCE_FILE" "$APT_SOURCE"
if [ "$APT_SOURCE_CHANGED" = "1" ]; then
    apt_update_force
else
    apt_update_once
fi

# Installs gh, or upgrades a distro-packaged gh to the repository release.
sudo apt-get install -y --no-install-recommends gh

echo "gh $(command_version gh || echo unknown) installed from cli.github.com."
