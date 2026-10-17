#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"

echo "Installing Go..."

if is_macos; then
    echo "macOS detected. Go is managed via Homebrew (install/Brewfile)."
    exit 0
fi

if command -v pacman >/dev/null 2>&1; then
    if command -v go >/dev/null 2>&1; then
        echo "Go is already installed."
        exit 0
    fi
    pacman_install go
    echo "Go installed via pacman."
    exit 0
fi

if ! is_linux; then
    echo "Unsupported platform for the Go installer."
    exit 1
fi

source_versions "$SCRIPT_DIR"

if [ -z "${GO_VERSION:-}" ]; then
    echo "GO_VERSION is missing. Run scripts/bump-versions.sh to refresh install/versions.env."
    exit 1
fi

# The official tarball replaces the distro golang-go package, which can be
# several releases behind (e.g. Go 1.18 on Ubuntu 22.04).
GO_ROOT="/usr/local/go"
if pinned_version_satisfied "$GO_VERSION" go "$GO_ROOT/bin/go"; then
    exit 0
fi

GO_ARCH_TOKEN="$(get_arch)"
case "$GO_ARCH_TOKEN" in
    x86_64)
        GO_ARCH="amd64"
        ;;
    arm64)
        GO_ARCH="arm64"
        ;;
esac

EXPECTED_VAR="GO_TAR_SHA256_${GO_ARCH_TOKEN}"
EXPECTED_GO_SHA="${!EXPECTED_VAR:-}"
GO_ARCHIVE="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
download_and_verify \
    "https://go.dev/dl/${GO_ARCHIVE}" \
    "$TMP_DIR/$GO_ARCHIVE" \
    "$EXPECTED_GO_SHA" \
    "Go tarball (${GO_ARCH})"

sudo rm -rf "$GO_ROOT"
sudo tar -C "$(dirname "$GO_ROOT")" -xzf "$TMP_DIR/$GO_ARCHIVE"
sudo ln -sfn "$GO_ROOT/bin/go" /usr/local/bin/go
sudo ln -sfn "$GO_ROOT/bin/gofmt" /usr/local/bin/gofmt

echo "Go ${GO_VERSION} installed to $GO_ROOT."
