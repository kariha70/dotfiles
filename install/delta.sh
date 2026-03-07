#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"
source_versions "$SCRIPT_DIR"

echo "Installing git-delta..."

if is_macos; then
    echo "macOS detected. git-delta is managed via Homebrew (install/Brewfile)."
    exit 0
fi

if command -v delta &> /dev/null; then
    echo "git-delta is already installed."
    exit 0
fi

# Try installing via apt (available in newer Ubuntu/Debian)
if command -v apt-get &> /dev/null; then
    if apt_package_available git-delta; then
        apt_update_once
        sudo apt-get install -y --no-install-recommends git-delta
        echo "git-delta installed via apt."
        exit 0
    fi
fi

# Fallback: Download .deb from GitHub (for x86_64)
# We use a fixed version for stability, but you might want to fetch the latest release tag.
if [ -z "${DELTA_VERSION:-}" ]; then
    echo "DELTA_VERSION is missing. Run scripts/bump-versions.sh to refresh install/versions.env."
    exit 1
fi

ARCH="$(get_arch)"
case "$ARCH" in
    x86_64)
        DELTA_ARCH="amd64"
        ;;
    arm64)
        DELTA_ARCH="arm64"
        ;;
esac

EXPECTED_DELTA_VAR="DELTA_DEB_SHA256_${DELTA_ARCH}"
EXPECTED_DELTA_SHA="${!EXPECTED_DELTA_VAR:-}"

DEB_FILE="git-delta_${DELTA_VERSION}_${DELTA_ARCH}.deb"
URL="https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/${DEB_FILE}"

echo "Downloading git-delta $DELTA_VERSION from GitHub..."
TMP_DEB="$(mktemp /tmp/git-delta.XXXXXX.deb)"
trap 'rm -f "$TMP_DEB"' EXIT
download_and_verify "$URL" "$TMP_DEB" "$EXPECTED_DELTA_SHA" "git-delta deb (${DELTA_ARCH})"

echo "Installing..."
sudo dpkg -i "$TMP_DEB"

echo "git-delta installed successfully."
