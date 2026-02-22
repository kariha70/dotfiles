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

echo "Installing lazygit..."

if command -v is_macos >/dev/null 2>&1 && is_macos; then
    echo "macOS detected. lazygit is managed via Homebrew (install/Brewfile)."
    exit 0
fi

if command -v lazygit &> /dev/null; then
    echo "lazygit is already installed."
    exit 0
fi

if [ -z "${LAZYGIT_VERSION:-}" ]; then
    echo "LAZYGIT_VERSION is missing. Run scripts/bump-versions.sh to refresh install/versions.env."
    exit 1
fi

LAZYGIT_ARCH="$(get_arch)"

EXPECTED_VAR="LAZYGIT_TAR_SHA256_${LAZYGIT_ARCH}"
EXPECTED_LAZYGIT_SHA="${!EXPECTED_VAR:-}"

TMP_TAR="$(mktemp /tmp/lazygit.XXXXXX.tar.gz)"
trap 'rm -f "$TMP_TAR"' EXIT
curl -fLsS "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz" -o "$TMP_TAR"
verify_sha256 "$TMP_TAR" "$EXPECTED_LAZYGIT_SHA" "lazygit tarball (${LAZYGIT_ARCH})"
tar xf "$TMP_TAR" -C /tmp lazygit
sudo install /tmp/lazygit /usr/local/bin
rm -f /tmp/lazygit

echo "lazygit installed successfully."
