#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"

echo "Installing MesloLGS NF fonts..."

source_versions "$SCRIPT_DIR"

if is_macos; then
    FONT_DIR="$HOME/Library/Fonts"
else
    FONT_DIR="$HOME/.local/share/fonts"
fi
mkdir -p "$FONT_DIR"

verify_font() {
    local file="$1" url="$2" env_var="$3" target expected
    target="$FONT_DIR/$file"
    if [ -f "$target" ]; then
        return
    fi
    curl -fLsS "$url" -o "$target"
    expected="${!env_var:-}"
    if [ -z "$expected" ]; then
        echo "Missing checksum for $file. Run scripts/bump-versions.sh to refresh install/versions.env."
        rm -f "$target"
        exit 1
    fi
    if ! verify_sha256 "$target" "$expected" "$file"; then
        echo "Checksum mismatch for $file"
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

if is_macos; then
    echo "MesloLGS NF fonts installed successfully in $FONT_DIR."
else
    # Reset font cache
    if command -v fc-cache >/dev/null 2>&1; then
        echo "Resetting font cache..."
        fc-cache -f -v "$FONT_DIR"
    else
        echo "fc-cache not found. Please install fontconfig."
    fi

    echo "MesloLGS NF fonts installed successfully."
fi
