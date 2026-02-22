#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HELPERS="$SCRIPT_DIR/lib/helpers.sh"
if [ -f "$HELPERS" ]; then
    # shellcheck source=/dev/null
    source "$HELPERS"
fi
if ! command -v is_macos >/dev/null 2>&1; then
    is_macos() { [ "$(uname -s)" = "Darwin" ]; }
fi

echo "Installing MesloLGS NF fonts..."

if is_macos; then
    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew is not available. Install Homebrew, then rerun install/fonts.sh."
        exit 1
    fi

    if brew list --cask font-meslo-lg-nerd-font >/dev/null 2>&1; then
        echo "font-meslo-lg-nerd-font is already installed."
    else
        brew install --cask font-meslo-lg-nerd-font
    fi

    echo "MesloLGS NF fonts installed successfully on macOS."
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

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

if ! command -v verify_sha256 >/dev/null 2>&1; then
    verify_sha256() {
        local file="$1" expected="$2"
        local actual
        if command -v sha256sum >/dev/null 2>&1; then
            actual=$(sha256sum "$file" | awk '{print $1}')
        elif command -v shasum >/dev/null 2>&1; then
            actual=$(shasum -a 256 "$file" | awk '{print $1}')
        else
            echo "No SHA256 tool found (need sha256sum or shasum)." >&2
            return 1
        fi
        [ "$actual" = "$expected" ]
    }
fi

verify_font() {
    local file="$1" url="$2" env_var="$3" target expected
    target="$FONT_DIR/$file"
    if [ -f "$target" ]; then
        return
    fi
    curl -fLo "$target" "$url"
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

# Reset font cache
if command -v fc-cache >/dev/null 2>&1; then
    echo "Resetting font cache..."
    fc-cache -f -v "$FONT_DIR"
else
    echo "fc-cache not found. Please install fontconfig."
fi

echo "MesloLGS NF fonts installed successfully."
