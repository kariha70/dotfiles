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

echo "Installing uv..."

if command -v uv &> /dev/null; then
    echo "uv is already installed."
else
    # Download installer script, require checksum to avoid running unverified code
    INSTALLER_PATH=/tmp/uv-install.sh
    curl -LsSf https://astral.sh/uv/install.sh -o "$INSTALLER_PATH"
    ACTUAL_SHA=$(sha256sum "$INSTALLER_PATH" | awk '{print $1}')
    EXPECTED_SHA="${UV_INSTALLER_SHA256:-}"
    if [ -z "$EXPECTED_SHA" ]; then
        echo "UV_INSTALLER_SHA256 missing. Run scripts/bump-versions.sh to refresh install/versions.env."
        rm -f "$INSTALLER_PATH"
        exit 1
    fi
    if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
        echo "Checksum mismatch for uv installer."
        echo "Expected: $EXPECTED_SHA"
        echo "Actual:   $ACTUAL_SHA"
        echo "Update install/versions.env with scripts/bump-versions.sh if a new release is available."
        exit 1
    fi
    sh "$INSTALLER_PATH"
    rm -f "$INSTALLER_PATH"
fi
