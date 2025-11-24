#!/bin/bash

set -e

FONT_DIR="$HOME/.local/share/fonts"

echo "Installing MesloLGS NF fonts..."

mkdir -p "$FONT_DIR"

# Download fonts
# Using URLs recommended by Powerlevel10k
if [ ! -f "$FONT_DIR/MesloLGS NF Regular.ttf" ]; then
    curl -fLo "$FONT_DIR/MesloLGS NF Regular.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
fi
if [ ! -f "$FONT_DIR/MesloLGS NF Bold.ttf" ]; then
    curl -fLo "$FONT_DIR/MesloLGS NF Bold.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
fi
if [ ! -f "$FONT_DIR/MesloLGS NF Italic.ttf" ]; then
    curl -fLo "$FONT_DIR/MesloLGS NF Italic.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
fi
if [ ! -f "$FONT_DIR/MesloLGS NF Bold Italic.ttf" ]; then
    curl -fLo "$FONT_DIR/MesloLGS NF Bold Italic.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf
fi

# Reset font cache
if command -v fc-cache &> /dev/null; then
    echo "Resetting font cache..."
    fc-cache -f -v "$FONT_DIR"
else
    echo "fc-cache not found. Please install fontconfig."
fi

echo "MesloLGS NF fonts installed successfully."
