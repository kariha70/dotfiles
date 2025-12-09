#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VERSIONS_FILE="${VERSIONS_FILE:-$SCRIPT_DIR/versions.env}"
if [ -f "$VERSIONS_FILE" ]; then
    # shellcheck source=/dev/null
    source "$VERSIONS_FILE"
else
    echo "versions.env not found at $VERSIONS_FILE. Run scripts/bump-versions.sh to generate it."
    exit 1
fi

FONT_DIR="$HOME/.local/share/fonts"

echo "Installing MesloLGS NF fonts..."

mkdir -p "$FONT_DIR"

verify_font() {
    local file="$1" url="$2" env_var="$3" target sha expected
    target="$FONT_DIR/$file"
    if [ -f "$target" ]; then
        return
    fi
    curl -fLo "$target" "$url"
    sha=$(sha256sum "$target" | awk '{print $1}')
    expected="${!env_var:-}"
    if [ -z "$expected" ]; then
        echo "SHA256 for $file: $sha"
        echo "Set $env_var or update install/versions.env (run scripts/bump-versions.sh) to proceed."
        rm -f "$target"
        exit 1
    fi
    if [ "$sha" != "$expected" ]; then
        echo "Checksum mismatch for $file"
        echo "Expected: $expected"
        echo "Actual:   $sha"
        rm -f "$target"
        exit 1
    fi
}

# Download fonts
# Using URLs recommended by Powerlevel10k
verify_font "MesloLGS NF Regular.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf MESLO_REGULAR_TTF_SHA256
verify_font "MesloLGS NF Bold.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf MESLO_BOLD_TTF_SHA256
verify_font "MesloLGS NF Italic.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf MESLO_ITALIC_TTF_SHA256
verify_font "MesloLGS NF Bold Italic.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf MESLO_BOLD_ITALIC_TTF_SHA256

# Reset font cache
if command -v fc-cache &> /dev/null; then
    echo "Resetting font cache..."
    fc-cache -f -v "$FONT_DIR"
else
    echo "fc-cache not found. Please install fontconfig."
fi

echo "MesloLGS NF fonts installed successfully."
