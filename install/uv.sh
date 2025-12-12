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

echo "Installing uv..."

if command -v uv &> /dev/null; then
    echo "uv is already installed."
else
    # Download installer script, require checksum to avoid running unverified code
    EXPECTED_SHA="${UV_INSTALLER_SHA256:-}"
    INSTALLER_PATH="$(mktemp /tmp/uv-install.XXXXXX.sh)"
    trap 'rm -f "$INSTALLER_PATH"' EXIT
    curl -LsSf https://astral.sh/uv/install.sh -o "$INSTALLER_PATH"
    verify_sha256 "$INSTALLER_PATH" "$EXPECTED_SHA" "uv installer"
    sh "$INSTALLER_PATH"
fi
