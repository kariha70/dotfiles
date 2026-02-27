#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"
source_versions "$SCRIPT_DIR"

echo "Installing lazygit..."

if is_macos; then
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

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
TMP_TAR="$TMP_DIR/lazygit.tar.gz"
download_and_verify "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz" "$TMP_TAR" "$EXPECTED_LAZYGIT_SHA" "lazygit tarball (${LAZYGIT_ARCH})"
tar xf "$TMP_TAR" -C "$TMP_DIR" lazygit
sudo install "$TMP_DIR/lazygit" /usr/local/bin

echo "lazygit installed successfully."
