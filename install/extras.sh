#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HELPERS="$SCRIPT_DIR/lib/helpers.sh"
if [ -f "$HELPERS" ]; then
    # shellcheck source=/dev/null
    source "$HELPERS"
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
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        FASTFETCH_ARCH="linux-amd64"
        YAZI_ARCH="x86_64-unknown-linux-gnu"
        ATUIN_ARCH="x86_64-unknown-linux-gnu"
        GLOW_ARCH="amd64.deb"
        GLOW_DEFAULT_DEB_SHA256="4d34c7100b1ee6d6eb74ea2513bf076b361489b5165394ac8f21a3485f982d99"
        ;;
    aarch64|arm64)
        FASTFETCH_ARCH="linux-aarch64"
        YAZI_ARCH="aarch64-unknown-linux-gnu"
        ATUIN_ARCH="aarch64-unknown-linux-gnu"
        GLOW_ARCH="arm64.deb"
        GLOW_DEFAULT_DEB_SHA256="51abf1f0aa8b686ef29bbebb96b758b6286c11d0e5ab38b5265ae8bf5bf9494c"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

verify_sha256() {
    local file="$1" expected="$2" label="$3"
    local actual
    actual=$(sha256sum "$file" | awk '{print $1}')
    if [ -z "$expected" ]; then
        echo "Missing checksum for $label. Run scripts/bump-versions.sh to refresh install/versions.env."
        return 1
    fi
    if [ "$actual" != "$expected" ]; then
        echo "Checksum mismatch for $label"
        echo "Expected: $expected"
        echo "Actual:   $actual"
        echo "Run scripts/bump-versions.sh if a new release is available."
        return 1
    fi
}

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

# 1. Glow (Markdown reader)
if ! command -v glow &> /dev/null; then
    echo "Installing Glow..."
    # Download latest release .deb from GitHub with checksum enforcement
    GLOW_URL=$(curl -s https://api.github.com/repos/charmbracelet/glow/releases/latest | jq -r --arg DEB "$GLOW_ARCH" '.assets[] | select(.name | endswith($DEB)) | .browser_download_url' | head -1)
    if [ -z "$GLOW_URL" ] || [ "$GLOW_URL" = "null" ]; then
        echo "Could not find Glow release asset for $GLOW_ARCH."
        exit 1
    fi
    curl -fLo /tmp/glow.deb "$GLOW_URL"
    GLOW_EXPECTED_SHA="${GLOW_DEB_SHA256:-$GLOW_DEFAULT_DEB_SHA256}"
    if ! verify_sha256 /tmp/glow.deb "$GLOW_EXPECTED_SHA" "GLOW_DEB_SHA256"; then
        if [ -z "${GLOW_DEB_SHA256:-}" ]; then
            echo "If the release changed, set GLOW_DEB_SHA256 to the new SHA256 after verifying it."
        fi
        exit 1
    fi
    apt_update_once
    sudo apt-get install -y /tmp/glow.deb
    rm -f /tmp/glow.deb
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
    curl -fLo /tmp/atuin.tar.gz "$ATUIN_URL"
    verify_sha256 /tmp/atuin.tar.gz "$ATUIN_EXPECTED" "Atuin ($ATUIN_ARCH)"
    tar -xf /tmp/atuin.tar.gz -C /tmp
    ATUIN_BIN=$(find /tmp -maxdepth 3 -type f -name atuin | head -1)
    if [ -z "$ATUIN_BIN" ]; then
        echo "Atuin binary not found in extracted archive."
        exit 1
    fi
    install -m 0755 "$ATUIN_BIN" "$HOME/.local/bin/atuin"
    rm -rf /tmp/atuin.tar.gz /tmp/atuin*
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
           curl -fLo /tmp/fastfetch.deb "$FF_URL"
           verify_sha256 /tmp/fastfetch.deb "$FF_EXPECTED" "Fastfetch ($FASTFETCH_ARCH)"
           sudo dpkg -i /tmp/fastfetch.deb
           rm /tmp/fastfetch.deb
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
    curl -fLo /tmp/yazi.zip "$YAZI_URL"
    verify_sha256 /tmp/yazi.zip "$YAZI_EXPECTED" "Yazi ($YAZI_ARCH)"
    unzip -q /tmp/yazi.zip -d /tmp
    # Move binary to local bin
    mv /tmp/yazi-*-linux-gnu/yazi "$HOME/.local/bin/"
    # Also move 'ya' if it exists (helper tool)
    for YA_BIN in /tmp/yazi-*-linux-gnu/ya; do
        if [ -f "$YA_BIN" ]; then
            mv "$YA_BIN" "$HOME/.local/bin/"
        fi
    done
    rm -rf /tmp/yazi*
    echo "Yazi installed."
else
    echo "Yazi is already installed."
fi

echo "Extras installation complete."
