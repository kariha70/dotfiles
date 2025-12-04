#!/bin/bash

set -e

echo "Installing lazygit..."

if command -v lazygit &> /dev/null; then
    echo "lazygit is already installed."
    exit 0
fi

ARCH=$(uname -m)
case $ARCH in
    x86_64)
        LAZYGIT_ARCH="x86_64"
        ;;
    aarch64|arm64)
        LAZYGIT_ARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
rm lazygit lazygit.tar.gz

echo "lazygit installed successfully."
