#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VERSIONS_FILE="${VERSIONS_FILE:-$SCRIPT_DIR/versions.env}"
if [ -f "$VERSIONS_FILE" ]; then
    # shellcheck source=/dev/null
    source "$VERSIONS_FILE"
else
    echo "versions.env not found at $VERSIONS_FILE. Run scripts/bump-versions.sh to generate it."
    exit 1
fi

echo "Installing git-delta..."

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

ARCH=$(uname -m)
case $ARCH in
    x86_64)
        DELTA_ARCH="amd64"
        ;;
    aarch64|arm64)
        DELTA_ARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

EXPECTED_DELTA_VAR="DELTA_DEB_SHA256_${DELTA_ARCH}"
EXPECTED_DELTA_SHA="${!EXPECTED_DELTA_VAR:-}"
if [ -z "$EXPECTED_DELTA_SHA" ]; then
    echo "Missing checksum for ${DELTA_ARCH} in install/versions.env (${EXPECTED_DELTA_VAR}). Run scripts/bump-versions.sh."
    exit 1
fi

DEB_FILE="git-delta_${DELTA_VERSION}_${DELTA_ARCH}.deb"
URL="https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/${DEB_FILE}"

echo "Downloading git-delta $DELTA_VERSION from GitHub..."
curl -fLo "/tmp/$DEB_FILE" "$URL"
DELTA_SHA=$(sha256sum "/tmp/$DEB_FILE" | awk '{print $1}')
if [ "$DELTA_SHA" != "$EXPECTED_DELTA_SHA" ]; then
    echo "Checksum mismatch for git-delta deb."
    echo "Expected: $EXPECTED_DELTA_SHA"
    echo "Actual:   $DELTA_SHA"
    echo "Update install/versions.env with scripts/bump-versions.sh if a new release is available."
    rm -f "/tmp/$DEB_FILE"
    exit 1
fi

echo "Installing..."
sudo dpkg -i "/tmp/$DEB_FILE"
rm "/tmp/$DEB_FILE"

echo "git-delta installed successfully."
