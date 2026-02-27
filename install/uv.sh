#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"
source_versions "$SCRIPT_DIR"

echo "Installing uv..."

if command -v uv &> /dev/null; then
    echo "uv is already installed."
else
    # Download installer script, require checksum to avoid running unverified code
    EXPECTED_SHA="${UV_INSTALLER_SHA256:-}"
    INSTALLER_PATH="$(mktemp /tmp/uv-install.XXXXXX.sh)"
    trap 'rm -f "$INSTALLER_PATH"' EXIT
    download_and_verify "https://astral.sh/uv/install.sh" "$INSTALLER_PATH" "$EXPECTED_SHA" "uv installer"
    sh "$INSTALLER_PATH"
fi
