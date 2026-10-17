#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"
source_versions "$SCRIPT_DIR"

echo "Installing zoxide..."

if is_macos; then
    echo "macOS detected. zoxide is managed via Homebrew (install/Brewfile)."
    exit 0
fi

if command -v pacman >/dev/null 2>&1; then
    if command -v zoxide >/dev/null 2>&1; then
        echo "zoxide is already installed."
        exit 0
    fi
    pacman_install zoxide
    echo "zoxide installed via pacman."
    exit 0
fi

if [ -z "${ZOXIDE_VERSION:-}" ]; then
    echo "ZOXIDE_VERSION is missing. Run scripts/bump-versions.sh to refresh install/versions.env."
    exit 1
fi

ZOXIDE_BIN="$HOME/.local/bin/zoxide"
if pinned_version_satisfied "$ZOXIDE_VERSION" zoxide "$ZOXIDE_BIN"; then
    exit 0
fi

ZOXIDE_ARCH="$(get_arch)"
case "$ZOXIDE_ARCH" in
    x86_64)
        ZOXIDE_TARGET="x86_64-unknown-linux-musl"
        ;;
    arm64)
        ZOXIDE_TARGET="aarch64-unknown-linux-musl"
        ;;
esac

EXPECTED_VAR="ZOXIDE_TAR_SHA256_${ZOXIDE_ARCH}"
EXPECTED_ZOXIDE_SHA="${!EXPECTED_VAR:-}"
ZOXIDE_ARCHIVE="zoxide-${ZOXIDE_VERSION}-${ZOXIDE_TARGET}.tar.gz"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
download_and_verify \
    "https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/${ZOXIDE_ARCHIVE}" \
    "$TMP_DIR/$ZOXIDE_ARCHIVE" \
    "$EXPECTED_ZOXIDE_SHA" \
    "zoxide tarball (${ZOXIDE_ARCH})"
tar xf "$TMP_DIR/$ZOXIDE_ARCHIVE" -C "$TMP_DIR" zoxide

ensure_local_bin
install -m 0755 "$TMP_DIR/zoxide" "$ZOXIDE_BIN"

echo "zoxide ${ZOXIDE_VERSION} installed to $ZOXIDE_BIN."
