#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HELPERS="$SCRIPT_DIR/lib/helpers.sh"
if [ -f "$HELPERS" ]; then
    # shellcheck source=/dev/null
    source "$HELPERS"
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
        ;;
    aarch64|arm64)
        FASTFETCH_ARCH="linux-aarch64"
        YAZI_ARCH="aarch64-unknown-linux-gnu"
        ATUIN_ARCH="aarch64-unknown-linux-gnu"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

verify_sha256() {
    local file="$1" expected="$2" env_name="$3"
    local actual
    actual=$(sha256sum "$file" | awk '{print $1}')
    if [ -z "$expected" ]; then
        echo "SHA256 for $file: $actual"
        echo "Set $env_name to the value above to proceed (aborting to avoid running an unverified download)."
        return 1
    fi
    if [ "$actual" != "$expected" ]; then
        echo "Checksum mismatch for $file"
        echo "Expected: $expected"
        echo "Actual:   $actual"
        return 1
    fi
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
    # Add Charm repo
    sudo mkdir -p /etc/apt/keyrings
    if [ ! -f /etc/apt/keyrings/charm.gpg ]; then
        curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    fi
    if [ ! -f /etc/apt/sources.list.d/charm.list ]; then
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ stable main" | sudo tee /etc/apt/sources.list.d/charm.list
        apt_update_once --force
    else
        apt_update_once
    fi
    sudo apt-get install -y glow
else
    echo "Glow is already installed."
fi

# 2. Atuin (Shell history)
if ! command -v atuin &> /dev/null; then
    echo "Installing Atuin..."
    ATUIN_URL=$(curl -s https://api.github.com/repos/atuinsh/atuin/releases/latest | jq -r --arg ARCH "$ATUIN_ARCH" '.assets[] | select(.name | endswith($ARCH + ".tar.gz")) | .browser_download_url' | head -1)
    if [ -z "$ATUIN_URL" ] || [ "$ATUIN_URL" = "null" ]; then
        echo "Could not find Atuin release asset for $ATUIN_ARCH."
        exit 1
    fi
    curl -fLo /tmp/atuin.tar.gz "$ATUIN_URL"
    verify_sha256 /tmp/atuin.tar.gz "${ATUIN_TAR_SHA256:-}" "ATUIN_TAR_SHA256"
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
           LATEST_URL=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | jq -r --arg ARCH "$FASTFETCH_ARCH" '.assets[] | select(.name | endswith($ARCH + ".deb")) | .browser_download_url' | head -1)
           if [ -n "$LATEST_URL" ] && [ "$LATEST_URL" != "null" ]; then
               curl -fLo /tmp/fastfetch.deb "$LATEST_URL"
               verify_sha256 /tmp/fastfetch.deb "${FASTFETCH_DEB_SHA256:-}" "FASTFETCH_DEB_SHA256"
               sudo dpkg -i /tmp/fastfetch.deb
               rm /tmp/fastfetch.deb
           else
               echo "Could not find fastfetch deb asset."
           fi
        fi
else
    echo "Fastfetch is already installed."
fi

# 4. Yazi (File manager)
if ! command -v yazi &> /dev/null; then
    echo "Installing Yazi..."
    # Download prebuilt binary
    LATEST_URL=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest | jq -r --arg ARCH "$YAZI_ARCH" '.assets[] | select(.name | contains($ARCH + ".zip")) | .browser_download_url' | head -1)
    if [ -n "$LATEST_URL" ] && [ "$LATEST_URL" != "null" ]; then
        curl -fLo /tmp/yazi.zip "$LATEST_URL"
        verify_sha256 /tmp/yazi.zip "${YAZI_ZIP_SHA256:-}" "YAZI_ZIP_SHA256"
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
        echo "Could not find yazi zip asset."
    fi
else
    echo "Yazi is already installed."
fi

echo "Extras installation complete."
