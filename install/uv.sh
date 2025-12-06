#!/bin/bash

set -e

echo "Installing uv..."

if command -v uv &> /dev/null; then
    echo "uv is already installed."
else
    # Download installer script, require checksum to avoid running unverified code
    INSTALLER_PATH=/tmp/uv-install.sh
    curl -LsSf https://astral.sh/uv/install.sh -o "$INSTALLER_PATH"
    ACTUAL_SHA=$(sha256sum "$INSTALLER_PATH" | awk '{print $1}')
    if [ -z "${UV_INSTALLER_SHA256:-}" ]; then
        echo "Installer SHA256: $ACTUAL_SHA"
        echo "Set UV_INSTALLER_SHA256 to the value above to proceed (aborting to avoid running an unverified installer)."
        exit 1
    fi
    if [ "$ACTUAL_SHA" != "$UV_INSTALLER_SHA256" ]; then
        echo "Checksum mismatch for uv installer."
        echo "Expected: $UV_INSTALLER_SHA256"
        echo "Actual:   $ACTUAL_SHA"
        exit 1
    fi
    sh "$INSTALLER_PATH"
    rm -f "$INSTALLER_PATH"
fi
