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

echo "Installing git-delta..."

if command -v is_macos >/dev/null 2>&1 && is_macos; then
    echo "macOS detected. git-delta is managed via Homebrew (install/Brewfile)."
    exit 0
fi

if command -v delta &> /dev/null; then
    echo "git-delta is already installed."
    exit 0
fi

# Try installing via apt (available in newer Ubuntu/Debian)
if command -v apt-get &> /dev/null; then
    if sudo apt-get install -y git-delta 2>/dev/null; then
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
curl -fLsS "$URL" -o "$TMP_DEB"
verify_sha256 "$TMP_DEB" "$EXPECTED_DELTA_SHA" "git-delta deb (${DELTA_ARCH})"

echo "Installing..."
sudo dpkg -i "$TMP_DEB"

echo "git-delta installed successfully."
