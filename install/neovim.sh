#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"
source_versions "$SCRIPT_DIR"

MINIMUM_VERSION="0.11.2"

version_at_least() {
    local have="$1" need="$2"
    [ "$(printf '%s\n%s\n' "$need" "$have" | sort -V | head -n 1)" = "$need" ]
}

normalize_version() {
    echo "${1%%-*}"
}

if is_macos; then
    echo "macOS detected. Neovim is managed via Homebrew (install/Brewfile)."
    exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required to install Neovim."
    exit 1
fi

if ! command -v nvim >/dev/null 2>&1; then
    echo "Neovim not found. Installing from pinned release appimage."
else
    current_version="$(normalize_version "$(nvim --version | awk '/^NVIM / {print $2}' | sed 's/^v//')")"
    if version_at_least "$current_version" "$MINIMUM_VERSION"; then
        echo "Neovim ${current_version} already satisfies minimum version (${MINIMUM_VERSION})."
        exit 0
    fi
    echo "Neovim ${current_version} is below minimum ${MINIMUM_VERSION}. Upgrading."
fi

if [ -z "${NEOVIM_VERSION:-}" ]; then
    echo "NEOVIM_VERSION is missing. Run scripts/bump-versions.sh to refresh install/versions.env."
    exit 1
fi

ARCH="$(get_arch)"
if [ -z "$ARCH" ]; then
    echo "Unsupported architecture for Neovim installer."
    exit 1
fi

if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "arm64" ]; then
    echo "Neovim installer currently supports x86_64 and arm64 only."
    exit 1
fi

EXPECTED_VAR="NEOVIM_APPIMAGE_SHA256_${ARCH}"
EXPECTED_SHA="${!EXPECTED_VAR:-}"
if [ -z "$EXPECTED_SHA" ]; then
    echo "Missing checksum for Neovim appimage. Run scripts/bump-versions.sh to refresh install/versions.env."
    exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

NEOVIM_ARCHIVE="$TMP_DIR/nvim-${ARCH}.appimage"
NEOVIM_URL="https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/nvim-linux-${ARCH}.appimage"

download_and_verify "$NEOVIM_URL" "$NEOVIM_ARCHIVE" "$EXPECTED_SHA" "Neovim appimage (${ARCH})"

sudo install -m 0755 "$NEOVIM_ARCHIVE" "/usr/local/bin/nvim"

installed_version="$(normalize_version "$(nvim --version | awk '/^NVIM / {print $2}' | sed 's/^v//')")"
if ! version_at_least "$installed_version" "$MINIMUM_VERSION"; then
    echo "Neovim upgrade failed; installed version ${installed_version} is below ${MINIMUM_VERSION}."
    exit 1
fi

echo "Neovim upgraded to ${installed_version}."
