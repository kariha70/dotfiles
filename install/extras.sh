#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HELPERS="$SCRIPT_DIR/lib/helpers.sh"
if [ -f "$HELPERS" ]; then
    # shellcheck source=/dev/null
    source "$HELPERS"
fi

if command -v is_macos >/dev/null 2>&1 && is_macos; then
    echo "macOS detected. Extras are managed via Homebrew (install/Brewfile)."
    exit 0
fi

VERSIONS_FILE="${VERSIONS_FILE:-$SCRIPT_DIR/versions.env}"
if [ -f "$VERSIONS_FILE" ]; then
    # shellcheck source=/dev/null
    source "$VERSIONS_FILE"
else
    echo "versions.env not found at $VERSIONS_FILE. Run scripts/bump-versions.sh to generate it."
    exit 1
fi
if ! command -v apt_update_once >/dev/null 2>&1; then
    apt_update_once() { sudo apt-get update; }
fi

echo "Installing extra modern tools (Glow, Atuin, Fastfetch, Yazi)..."

# Detect architecture
ARCH="$(get_arch)"
case "$ARCH" in
    x86_64)
        FASTFETCH_ARCH="linux-amd64"
        YAZI_ARCH="x86_64-unknown-linux-gnu"
        ATUIN_ARCH="x86_64-unknown-linux-gnu"
        GLOW_ARCH="amd64"
        ;;
    arm64)
        FASTFETCH_ARCH="linux-aarch64"
        YAZI_ARCH="aarch64-unknown-linux-gnu"
        ATUIN_ARCH="aarch64-unknown-linux-gnu"
        GLOW_ARCH="arm64"
        ;;
esac

var_for_arch() {
    echo "${1//-/_}"
}

# Ensure apt dependencies when available (for standalone runs)
if command -v apt-get &> /dev/null; then
    EXTRA_DEPS=()
    command -v jq >/dev/null 2>&1 || EXTRA_DEPS+=(jq)
    command -v unzip >/dev/null 2>&1 || EXTRA_DEPS+=(unzip)
    if [ "${#EXTRA_DEPS[@]}" -gt 0 ]; then
        apt_update_once
        sudo apt-get install -y "${EXTRA_DEPS[@]}"
    fi
fi

# Ensure ~/.local/bin exists
if command -v ensure_local_bin >/dev/null 2>&1; then
    ensure_local_bin
else
    mkdir -p "$HOME/.local/bin"
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# 1. Glow (Markdown reader)
if ! command -v glow &> /dev/null; then
    echo "Installing Glow..."
    if [ -z "${GLOW_VERSION:-}" ]; then
        echo "GLOW_VERSION is missing. Run scripts/bump-versions.sh."
        exit 1
    fi
    glow_version="${GLOW_VERSION#v}"
    GLOW_SHA_VAR="GLOW_DEB_SHA256_${GLOW_ARCH}"
    GLOW_EXPECTED_SHA="${!GLOW_SHA_VAR:-}"
    GLOW_URL="https://github.com/charmbracelet/glow/releases/download/${GLOW_VERSION}/glow_${glow_version}_${GLOW_ARCH}.deb"
    GLOW_DEB="$TMP_DIR/glow.deb"
    curl -fLsS "$GLOW_URL" -o "$GLOW_DEB"
    verify_sha256 "$GLOW_DEB" "$GLOW_EXPECTED_SHA" "Glow (${GLOW_ARCH})"
    apt_update_once
    sudo apt-get install -y "$GLOW_DEB"
else
    echo "Glow is already installed."
fi

# 2. Atuin (Shell history)
if ! command -v atuin &> /dev/null; then
    echo "Installing Atuin..."
    if [ -z "${ATUIN_VERSION:-}" ]; then
        echo "ATUIN_VERSION is missing. Run scripts/bump-versions.sh."
        exit 1
    fi
    ATUIN_SHA_VAR="ATUIN_TAR_SHA256_$(var_for_arch "$ATUIN_ARCH")"
    ATUIN_EXPECTED="${!ATUIN_SHA_VAR:-}"
    ATUIN_URL="https://github.com/atuinsh/atuin/releases/download/${ATUIN_VERSION}/atuin-${ATUIN_ARCH}.tar.gz"
    ATUIN_TAR="$TMP_DIR/atuin.tar.gz"
    curl -fLsS "$ATUIN_URL" -o "$ATUIN_TAR"
    verify_sha256 "$ATUIN_TAR" "$ATUIN_EXPECTED" "Atuin ($ATUIN_ARCH)"
    tar -xf "$ATUIN_TAR" -C "$TMP_DIR"
    ATUIN_BIN=$(find "$TMP_DIR" -maxdepth 3 -type f -name atuin | head -1)
    if [ -z "$ATUIN_BIN" ]; then
        echo "Atuin binary not found in extracted archive."
        exit 1
    fi
    install -m 0755 "$ATUIN_BIN" "$HOME/.local/bin/atuin"
    echo "Atuin installed."
else
    echo "Atuin is already installed."
fi

# 3. Fastfetch
if ! command -v fastfetch &> /dev/null; then
    echo "Installing Fastfetch..."
    # Try apt first (available in Ubuntu 24.10+)
    if sudo apt-get install -y fastfetch 2>/dev/null; then
        echo "Fastfetch installed via apt."
        else
           # Fallback to GitHub release (with checksum enforcement)
           echo "Fastfetch not in apt, downloading from GitHub..."
           if [ -z "${FASTFETCH_VERSION:-}" ]; then
               echo "FASTFETCH_VERSION is missing. Run scripts/bump-versions.sh."
               exit 1
           fi
           FF_SHA_VAR="FASTFETCH_DEB_SHA256_$(var_for_arch "$FASTFETCH_ARCH")"
           FF_EXPECTED="${!FF_SHA_VAR:-}"
           FF_URL="https://github.com/fastfetch-cli/fastfetch/releases/download/${FASTFETCH_VERSION}/fastfetch-${FASTFETCH_ARCH}.deb"
           FF_DEB="$TMP_DIR/fastfetch.deb"
           curl -fLsS "$FF_URL" -o "$FF_DEB"
           verify_sha256 "$FF_DEB" "$FF_EXPECTED" "Fastfetch ($FASTFETCH_ARCH)"
           sudo dpkg -i "$FF_DEB"
        fi
else
    echo "Fastfetch is already installed."
fi

# 4. Yazi (File manager)
if ! command -v yazi &> /dev/null; then
    echo "Installing Yazi..."
    if [ -z "${YAZI_VERSION:-}" ]; then
        echo "YAZI_VERSION is missing. Run scripts/bump-versions.sh."
        exit 1
    fi
    YAZI_SHA_VAR="YAZI_ZIP_SHA256_$(var_for_arch "$YAZI_ARCH")"
    YAZI_EXPECTED="${!YAZI_SHA_VAR:-}"
    YAZI_URL="https://github.com/sxyazi/yazi/releases/download/${YAZI_VERSION}/yazi-${YAZI_ARCH}.zip"
    YAZI_ZIP="$TMP_DIR/yazi.zip"
    curl -fLsS "$YAZI_URL" -o "$YAZI_ZIP"
    verify_sha256 "$YAZI_ZIP" "$YAZI_EXPECTED" "Yazi ($YAZI_ARCH)"
    unzip -q "$YAZI_ZIP" -d "$TMP_DIR"
    YAZI_DIR=$(find "$TMP_DIR" -maxdepth 1 -type d -name "yazi-*-linux-gnu" | head -1)
    if [ -z "$YAZI_DIR" ]; then
        echo "Yazi directory not found in extracted archive."
        exit 1
    fi
    mv "$YAZI_DIR/yazi" "$HOME/.local/bin/"
    if [ -f "$YAZI_DIR/ya" ]; then
        mv "$YAZI_DIR/ya" "$HOME/.local/bin/"
    fi
    echo "Yazi installed."
else
    echo "Yazi is already installed."
fi

echo "Extras installation complete."
