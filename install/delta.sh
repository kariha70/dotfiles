#!/bin/bash

set -e

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
VERSION="0.16.5"

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

DEB_FILE="git-delta_${VERSION}_${DELTA_ARCH}.deb"
URL="https://github.com/dandavison/delta/releases/download/${VERSION}/${DEB_FILE}"

echo "Downloading git-delta $VERSION from GitHub..."
curl -fLo "/tmp/$DEB_FILE" "$URL"

echo "Installing..."
sudo dpkg -i "/tmp/$DEB_FILE"
rm "/tmp/$DEB_FILE"

echo "git-delta installed successfully."
