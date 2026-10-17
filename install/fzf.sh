#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"

echo "Installing fzf..."

if is_macos; then
    echo "macOS detected. fzf is managed via Homebrew (install/Brewfile)."
    exit 0
fi

if command -v pacman >/dev/null 2>&1; then
    if command -v fzf >/dev/null 2>&1; then
        echo "fzf is already installed."
        exit 0
    fi
    pacman_install fzf
    echo "fzf installed via pacman."
    exit 0
fi

if ! is_linux; then
    echo "Unsupported platform for the fzf installer."
    exit 1
fi

source_versions "$SCRIPT_DIR"

if [ -z "${FZF_VERSION:-}" ]; then
    echo "FZF_VERSION is missing. Run scripts/bump-versions.sh to refresh install/versions.env."
    exit 1
fi

if pinned_version_satisfied "$FZF_VERSION" fzf /usr/local/bin/fzf; then
    exit 0
fi

FZF_ARCH_TOKEN="$(get_arch)"
case "$FZF_ARCH_TOKEN" in
    x86_64)
        FZF_ARCH="amd64"
        ;;
    arm64)
        FZF_ARCH="arm64"
        ;;
esac

EXPECTED_VAR="FZF_TAR_SHA256_${FZF_ARCH_TOKEN}"
EXPECTED_FZF_SHA="${!EXPECTED_VAR:-}"
FZF_ARCHIVE="fzf-${FZF_VERSION}-linux_${FZF_ARCH}.tar.gz"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
download_and_verify \
    "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/${FZF_ARCHIVE}" \
    "$TMP_DIR/$FZF_ARCHIVE" \
    "$EXPECTED_FZF_SHA" \
    "fzf tarball (${FZF_ARCH})"
tar xf "$TMP_DIR/$FZF_ARCHIVE" -C "$TMP_DIR" fzf
sudo install "$TMP_DIR/fzf" /usr/local/bin/fzf

echo "fzf ${FZF_VERSION} installed successfully."
