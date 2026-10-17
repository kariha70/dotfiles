#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"

echo "Installing pinned upstream releases of bat, fd, and hyperfine..."

if is_macos; then
    echo "macOS detected. bat, fd, and hyperfine are managed via Homebrew (install/Brewfile)."
    exit 0
fi

if command -v pacman >/dev/null 2>&1; then
    echo "Arch Linux detected. bat, fd, and hyperfine are installed by install/packages.sh."
    exit 0
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "Package manager not supported for upstream .deb installs; skipping."
    exit 0
fi

source_versions "$SCRIPT_DIR"

ARCH="$(get_arch)"
case "$ARCH" in
    x86_64)
        DEB_ARCH="amd64"
        ;;
    arm64)
        DEB_ARCH="arm64"
        ;;
esac

# The upstream packages replace Ubuntu's renamed variants: bat ships `bat`
# instead of `batcat`, and fd conflicts with fd-find while still providing
# an `fdfind` symlink for existing aliases.
# Usage: install_sharkdp_deb <command> <repo> <version> <sha-var-prefix>
install_sharkdp_deb() {
    local command_name="$1" repo="$2" version="$3" sha_prefix="$4"
    local sha_var expected_sha

    if [ -z "$version" ]; then
        echo "Pinned version for $command_name is missing. Run scripts/bump-versions.sh."
        exit 1
    fi

    if pinned_version_satisfied "$version" "$command_name"; then
        return 0
    fi

    sha_var="${sha_prefix}_${DEB_ARCH}"
    expected_sha="${!sha_var:-}"
    echo "Installing $command_name $version from GitHub..."
    install_verified_deb \
        "https://github.com/sharkdp/${repo}/releases/download/v${version}/${repo}_${version}_${DEB_ARCH}.deb" \
        "$expected_sha" \
        "$command_name deb (${DEB_ARCH})"
}

install_sharkdp_deb bat bat "${BAT_VERSION:-}" BAT_DEB_SHA256
install_sharkdp_deb fd fd "${FD_VERSION:-}" FD_DEB_SHA256
install_sharkdp_deb hyperfine hyperfine "${HYPERFINE_VERSION:-}" HYPERFINE_DEB_SHA256

echo "Upstream CLI tool installation complete."
