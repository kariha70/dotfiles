#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"
source_versions "$SCRIPT_DIR"

if is_wsl; then
    echo "WSL detected. Skipping font installation (install on the Windows host instead)."
    exit 0
fi

echo "Installing MesloLGS NF fonts..."

if [ -z "${POWERLEVEL10K_MEDIA_REF:-}" ]; then
    echo "Missing POWERLEVEL10K_MEDIA_REF. Run scripts/bump-versions.sh or update install/versions.env."
    exit 1
fi

if is_macos; then
    FONT_DIR="$HOME/Library/Fonts"
else
    FONT_DIR="$HOME/.local/share/fonts"
fi
mkdir -p "$FONT_DIR"

FONT_BASE_URL="https://raw.githubusercontent.com/romkatv/powerlevel10k-media/${POWERLEVEL10K_MEDIA_REF}"
FONTS_CHANGED=0

# style|checksum pin
for font in "Regular|MESLO_REGULAR_TTF_SHA256" "Bold|MESLO_BOLD_TTF_SHA256" \
    "Italic|MESLO_ITALIC_TTF_SHA256" "Bold Italic|MESLO_BOLD_ITALIC_TTF_SHA256"; do
    style="${font%%|*}"
    sha_var="${font#*|}"
    file="MesloLGS NF ${style}.ttf"
    target="$FONT_DIR/$file"
    expected="${!sha_var:-}"

    if [ -f "$target" ] && verify_sha256 "$target" "$expected" "$file" >/dev/null 2>&1; then
        continue
    fi

    temp_path="$(mktemp "${TMPDIR:-/tmp}/meslo-font.XXXXXX")"
    if ! download_and_verify "$FONT_BASE_URL/${file// /%20}" "$temp_path" "$expected" "$file"; then
        rm -f "$temp_path"
        exit 1
    fi
    mv "$temp_path" "$target"
    FONTS_CHANGED=1
done

if [ "$FONTS_CHANGED" -eq 0 ]; then
    echo "MesloLGS NF fonts already installed."
elif ! is_macos && command -v fc-cache >/dev/null 2>&1; then
    echo "Refreshing font cache..."
    fc-cache -f "$FONT_DIR"
fi

echo "MesloLGS NF fonts installed in $FONT_DIR."
