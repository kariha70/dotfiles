#!/bin/bash

set -e

echo "Installing uv..."

DEFAULT_UV_INSTALLER_SHA256="81b9594996c7ed9d95bbfb80e7fbdcc4fe1cc9ae83983b4ae86b39c603269207"

if command -v uv &> /dev/null; then
    echo "uv is already installed."
else
    # Download installer script, require checksum to avoid running unverified code
    INSTALLER_PATH=/tmp/uv-install.sh
    curl -LsSf https://astral.sh/uv/install.sh -o "$INSTALLER_PATH"
    ACTUAL_SHA=$(sha256sum "$INSTALLER_PATH" | awk '{print $1}')
    EXPECTED_SHA="${UV_INSTALLER_SHA256:-$DEFAULT_UV_INSTALLER_SHA256}"
    if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
        echo "Checksum mismatch for uv installer."
        echo "Expected: $EXPECTED_SHA"
        echo "Actual:   $ACTUAL_SHA"
        if [ -z "${UV_INSTALLER_SHA256:-}" ]; then
            echo "If the installer has changed, set UV_INSTALLER_SHA256 to the new value after verifying it."
        fi
        exit 1
    fi
    sh "$INSTALLER_PATH"
    rm -f "$INSTALLER_PATH"
fi
