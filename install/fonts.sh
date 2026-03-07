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
FONTS_CHANGED=0

install_font() {
    local file="$1" url="$2" env_var="$3" target expected temp_path
    target="$FONT_DIR/$file"
    expected="${!env_var:-}"
    if [ -z "$expected" ]; then
        echo "Missing checksum for $file. Run scripts/bump-versions.sh to refresh install/versions.env."
        exit 1
    fi

    if [ -f "$target" ] && verify_sha256 "$target" "$expected" "$file" >/dev/null 2>&1; then
        return 0
    fi

    temp_path="$(mktemp "${TMPDIR:-/tmp}/meslo-font.XXXXXX")"
    if ! download_and_verify "$url" "$temp_path" "$expected" "$file"; then
        rm -f "$temp_path"
        exit 1
    fi
    mv "$temp_path" "$target"
    FONTS_CHANGED=1
}

download_fonts_macos() {
    local -a pids=()

    install_font "MesloLGS NF Regular.ttf" "https://raw.githubusercontent.com/romkatv/powerlevel10k-media/${POWERLEVEL10K_MEDIA_REF}/MesloLGS%20NF%20Regular.ttf" MESLO_REGULAR_TTF_SHA256 &
    pids+=("$!")
    install_font "MesloLGS NF Bold.ttf" "https://raw.githubusercontent.com/romkatv/powerlevel10k-media/${POWERLEVEL10K_MEDIA_REF}/MesloLGS%20NF%20Bold.ttf" MESLO_BOLD_TTF_SHA256 &
    pids+=("$!")
    install_font "MesloLGS NF Italic.ttf" "https://raw.githubusercontent.com/romkatv/powerlevel10k-media/${POWERLEVEL10K_MEDIA_REF}/MesloLGS%20NF%20Italic.ttf" MESLO_ITALIC_TTF_SHA256 &
    pids+=("$!")
    install_font "MesloLGS NF Bold Italic.ttf" "https://raw.githubusercontent.com/romkatv/powerlevel10k-media/${POWERLEVEL10K_MEDIA_REF}/MesloLGS%20NF%20Bold%20Italic.ttf" MESLO_BOLD_ITALIC_TTF_SHA256 &
    pids+=("$!")

    for pid in "${pids[@]}"; do
        wait "$pid"
    done
}

download_fonts_other() {
    install_font "MesloLGS NF Regular.ttf" "https://raw.githubusercontent.com/romkatv/powerlevel10k-media/${POWERLEVEL10K_MEDIA_REF}/MesloLGS%20NF%20Regular.ttf" MESLO_REGULAR_TTF_SHA256
    install_font "MesloLGS NF Bold.ttf" "https://raw.githubusercontent.com/romkatv/powerlevel10k-media/${POWERLEVEL10K_MEDIA_REF}/MesloLGS%20NF%20Bold.ttf" MESLO_BOLD_TTF_SHA256
    install_font "MesloLGS NF Italic.ttf" "https://raw.githubusercontent.com/romkatv/powerlevel10k-media/${POWERLEVEL10K_MEDIA_REF}/MesloLGS%20NF%20Italic.ttf" MESLO_ITALIC_TTF_SHA256
    install_font "MesloLGS NF Bold Italic.ttf" "https://raw.githubusercontent.com/romkatv/powerlevel10k-media/${POWERLEVEL10K_MEDIA_REF}/MesloLGS%20NF%20Bold%20Italic.ttf" MESLO_BOLD_ITALIC_TTF_SHA256
}

if [ -z "${POWERLEVEL10K_MEDIA_REF:-}" ]; then
    echo "Missing POWERLEVEL10K_MEDIA_REF. Run scripts/bump-versions.sh or update install/versions.env."
    exit 1
fi

# Download fonts using pinned Powerlevel10k media URLs
if is_macos; then
    download_fonts_macos
else
    download_fonts_other
fi

if is_macos; then
    echo "MesloLGS NF fonts installed successfully in $FONT_DIR."
else
    # Reset font cache
    if [ "$FONTS_CHANGED" -eq 1 ] && command -v fc-cache >/dev/null 2>&1; then
        echo "Resetting font cache..."
        fc-cache -f "$FONT_DIR"
    elif [ "$FONTS_CHANGED" -eq 0 ]; then
        echo "Font files already present. Skipping font cache refresh."
    else
        echo "fc-cache not found. Please install fontconfig."
    fi

    echo "MesloLGS NF fonts installed successfully."
fi
