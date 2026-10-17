#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"
source_versions "$SCRIPT_DIR"

echo "Installing git-delta..."

if is_macos; then
    echo "macOS detected. git-delta is managed via Homebrew (install/Brewfile)."
    exit 0
fi

if command -v pacman >/dev/null 2>&1; then
    if command -v delta >/dev/null 2>&1; then
        echo "git-delta is already installed."
        exit 0
    fi
    pacman_install git-delta
    echo "git-delta installed via pacman."
    exit 0
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "Package manager not supported for automatic git-delta installation. Please install git-delta manually."
    exit 0
fi

# Install the pinned upstream .deb rather than the distro package so bumping
# DELTA_VERSION upgrades existing machines too.
if [ -z "${DELTA_VERSION:-}" ]; then
    echo "DELTA_VERSION is missing. Run scripts/bump-versions.sh to refresh install/versions.env."
    exit 1
fi

if pinned_version_satisfied "$DELTA_VERSION" delta; then
    exit 0
fi

ARCH="$(get_arch)"
case "$ARCH" in
    x86_64)
        DELTA_ARCH="amd64"
        ;;
    arm64)
        DELTA_ARCH="arm64"
        ;;
esac

EXPECTED_DELTA_VAR="DELTA_DEB_SHA256_${DELTA_ARCH}"
EXPECTED_DELTA_SHA="${!EXPECTED_DELTA_VAR:-}"

DEB_FILE="git-delta_${DELTA_VERSION}_${DELTA_ARCH}.deb"
URL="https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/${DEB_FILE}"

echo "Installing git-delta $DELTA_VERSION from GitHub..."
install_verified_deb "$URL" "$EXPECTED_DELTA_SHA" "git-delta deb (${DELTA_ARCH})"

echo "git-delta installed successfully."
