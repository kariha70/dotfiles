#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HELPERS="$SCRIPT_DIR/lib/helpers.sh"
if [ -f "$HELPERS" ]; then
    # shellcheck source=/dev/null
    source "$HELPERS"
fi

echo "Installing extra modern tools (Glow, Atuin, Fastfetch, Yazi)..."

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        FASTFETCH_ARCH="linux-amd64"
        YAZI_ARCH="x86_64-unknown-linux-gnu"
        ;;
    aarch64|arm64)
        FASTFETCH_ARCH="linux-aarch64"
        YAZI_ARCH="aarch64-unknown-linux-gnu"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

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
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
    sudo apt-get update
    sudo apt-get install -y glow
else
    echo "Glow is already installed."
fi

# 2. Atuin (Shell history)
if ! command -v atuin &> /dev/null; then
    echo "Installing Atuin..."
    # Install to ~/.local/bin (default)
    curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | sh -s -- --no-modify-path
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
        # Fallback to GitHub release
        echo "Fastfetch not in apt, downloading from GitHub..."
        LATEST_URL=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | jq -r --arg ARCH "$FASTFETCH_ARCH" '.assets[] | select(.name | endswith($ARCH + ".deb")) | .browser_download_url')
        if [ -n "$LATEST_URL" ] && [ "$LATEST_URL" != "null" ]; then
             curl -fLo /tmp/fastfetch.deb "$LATEST_URL"
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
    LATEST_URL=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest | jq -r --arg ARCH "$YAZI_ARCH" '.assets[] | select(.name | contains($ARCH + ".zip")) | .browser_download_url')
    if [ -n "$LATEST_URL" ] && [ "$LATEST_URL" != "null" ]; then
        curl -fLo /tmp/yazi.zip "$LATEST_URL"
        unzip -q /tmp/yazi.zip -d /tmp
        # Move binary to local bin
        mv /tmp/yazi-*-linux-gnu/yazi "$HOME/.local/bin/"
        # Also move 'ya' if it exists (helper tool)
        if [ -f /tmp/yazi-*-linux-gnu/ya ]; then
            mv /tmp/yazi-*-linux-gnu/ya "$HOME/.local/bin/"
        fi
        rm -rf /tmp/yazi*
        echo "Yazi installed."
    else
        echo "Could not find yazi zip asset."
    fi
else
    echo "Yazi is already installed."
fi

echo "Extras installation complete."
