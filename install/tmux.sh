#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"

echo "Installing tmux..."

if is_macos; then
    echo "macOS detected. tmux is managed via Homebrew (install/Brewfile)."
    exit 0
fi

if command -v pacman >/dev/null 2>&1; then
    if command -v tmux >/dev/null 2>&1; then
        echo "tmux is already installed."
        exit 0
    fi
    pacman_install tmux
    echo "tmux installed via pacman."
    exit 0
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "Package manager not supported for the tmux source build; skipping."
    exit 0
fi

source_versions "$SCRIPT_DIR"

if [ -z "${TMUX_VERSION:-}" ]; then
    echo "TMUX_VERSION is missing. Run scripts/bump-versions.sh to refresh install/versions.env."
    exit 1
fi

if pinned_version_satisfied "$TMUX_VERSION" tmux /usr/local/bin/tmux; then
    exit 0
fi

# tmux publishes source tarballs only, so build the pinned release into
# /usr/local. The distro package from install/packages.sh stays as a fallback.
apt_update_once
sudo apt-get install -y --no-install-recommends \
    build-essential pkg-config bison libevent-dev libncurses-dev

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
TMUX_ARCHIVE="tmux-${TMUX_VERSION}.tar.gz"
download_and_verify \
    "https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/${TMUX_ARCHIVE}" \
    "$TMP_DIR/$TMUX_ARCHIVE" \
    "${TMUX_TAR_SHA256:-}" \
    "tmux source tarball"
tar xzf "$TMP_DIR/$TMUX_ARCHIVE" -C "$TMP_DIR"

(
    cd "$TMP_DIR/tmux-${TMUX_VERSION}"
    ./configure --prefix=/usr/local >/dev/null
    make -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)" >/dev/null
    sudo make install >/dev/null
)

echo "tmux ${TMUX_VERSION} installed to /usr/local/bin/tmux."
if tmux list-sessions >/dev/null 2>&1; then
    echo "A tmux server is running; restart it to use tmux ${TMUX_VERSION}."
fi
