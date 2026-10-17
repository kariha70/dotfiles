#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"
source_versions "$SCRIPT_DIR"

MINIMUM_VERSION="0.11.2"

if is_macos; then
    echo "macOS detected. Neovim is managed via Homebrew (install/Brewfile)."
    exit 0
fi

if command -v pacman >/dev/null 2>&1; then
    if command -v nvim >/dev/null 2>&1; then
        current_version="$(normalize_version "$(nvim --version | awk '/^NVIM / {print $2}' | sed 's/^v//')")"
        if version_at_least "$current_version" "$MINIMUM_VERSION"; then
            echo "Neovim ${current_version} already satisfies minimum version (${MINIMUM_VERSION})."
            exit 0
        fi
    fi
    echo "Installing Neovim from the Arch Linux repositories..."
    pacman_install neovim
    installed_version="$(normalize_version "$(nvim --version | awk '/^NVIM / {print $2}' | sed 's/^v//')")"
    if ! version_at_least "$installed_version" "$MINIMUM_VERSION"; then
        echo "Neovim upgrade failed; installed version ${installed_version} is below ${MINIMUM_VERSION}."
        exit 1
    fi
    echo "Neovim upgraded to ${installed_version}."
    exit 0
fi

if [ -z "${NEOVIM_VERSION:-}" ]; then
    echo "NEOVIM_VERSION is missing. Run scripts/bump-versions.sh to refresh install/versions.env."
    exit 1
fi

if pinned_version_satisfied "$NEOVIM_VERSION" nvim /usr/local/bin/nvim; then
    exit 0
fi

echo "Installing Neovim ${NEOVIM_VERSION} from pinned release appimage."

ARCH="$(get_arch)"
release_info neovim "$ARCH"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

NEOVIM_ARCHIVE="$TMP_DIR/$RELEASE_ASSET"
download_and_verify "$RELEASE_URL" "$NEOVIM_ARCHIVE" "${!RELEASE_SHA_VAR:-}" "Neovim appimage (${ARCH})"

chmod +x "$NEOVIM_ARCHIVE"
(
    cd "$TMP_DIR"
    "$NEOVIM_ARCHIVE" --appimage-extract >/dev/null
)

NEOVIM_INSTALL_DIR="/usr/local/lib/nvim-${NEOVIM_VERSION}-${ARCH}"
PREVIOUS_INSTALL_DIR=""
if [ -L /usr/local/bin/nvim ]; then
    PREVIOUS_INSTALL_DIR="$(readlink -f /usr/local/bin/nvim || true)"
    PREVIOUS_INSTALL_DIR="${PREVIOUS_INSTALL_DIR%/usr/bin/nvim}"
fi
sudo install -d "$NEOVIM_INSTALL_DIR"
sudo cp -a "$TMP_DIR/squashfs-root/." "$NEOVIM_INSTALL_DIR/"
sudo ln -sfn "$NEOVIM_INSTALL_DIR/usr/bin/nvim" "/usr/local/bin/nvim"

# Remove older extracted releases, but keep the one being replaced: running
# Neovim sessions still load runtime files from their $VIMRUNTIME.
for old_dir in /usr/local/lib/nvim-*-"${ARCH}"; do
    if [ -d "$old_dir" ] && [ "$old_dir" != "$NEOVIM_INSTALL_DIR" ] && [ "$old_dir" != "$PREVIOUS_INSTALL_DIR" ]; then
        sudo rm -rf -- "$old_dir"
    fi
done

if ! pinned_version_satisfied "$NEOVIM_VERSION" /usr/local/bin/nvim; then
    echo "Neovim upgrade failed; /usr/local/bin/nvim does not report ${NEOVIM_VERSION}."
    exit 1
fi

echo "Neovim upgraded to ${NEOVIM_VERSION}."
