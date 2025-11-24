#!/bin/bash

set -e

echo "Installing zoxide..."

if command -v zoxide &> /dev/null; then
    echo "zoxide is already installed."
    exit 0
fi

# Install zoxide to ~/.local/bin
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

echo "zoxide installed."
