#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"
source_versions "$SCRIPT_DIR"

echo "Installing just..."

if is_macos; then
    echo "macOS detected. just is managed via Homebrew (install/Brewfile)."
    exit 0
fi

if command -v just >/dev/null 2>&1; then
    echo "just is already installed."
    exit 0
fi

if command -v pacman >/dev/null 2>&1; then
    pacman_install just
    echo "just installed via pacman."
    exit 0
fi

if ! is_linux; then
    echo "Unsupported platform for the just fallback installer."
    exit 1
fi

if [ -z "${JUST_VERSION:-}" ]; then
    echo "JUST_VERSION is missing. Run scripts/bump-versions.sh to refresh install/versions.env."
    exit 1
fi

JUST_ARCH="$(get_arch)"
case "$JUST_ARCH" in
    x86_64)
        JUST_TARGET="x86_64-unknown-linux-musl"
        ;;
    arm64)
        JUST_TARGET="aarch64-unknown-linux-musl"
        ;;
    *)
        echo "Unsupported architecture for just: $JUST_ARCH"
        exit 1
        ;;
esac

EXPECTED_VAR="JUST_TAR_SHA256_${JUST_ARCH}"
EXPECTED_JUST_SHA="${!EXPECTED_VAR:-}"
JUST_ARCHIVE="just-${JUST_VERSION}-${JUST_TARGET}.tar.gz"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
TMP_TAR="$TMP_DIR/$JUST_ARCHIVE"

download_and_verify \
    "https://github.com/casey/just/releases/download/${JUST_VERSION}/${JUST_ARCHIVE}" \
    "$TMP_TAR" \
    "$EXPECTED_JUST_SHA" \
    "just tarball (${JUST_ARCH})"
tar xf "$TMP_TAR" -C "$TMP_DIR" just
sudo install "$TMP_DIR/just" /usr/local/bin/just

echo "just installed successfully."
