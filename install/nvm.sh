#!/bin/bash

set -e

export NVM_DIR="$HOME/.nvm"

# Install nvm only if it is not already present
if [ -s "$NVM_DIR/nvm.sh" ]; then
    echo "nvm is already installed."
else
    echo "Installing nvm..."
    # We use PROFILE=/dev/null to prevent the install script from modifying .bashrc/.zshrc
    # because we manage those files ourselves.
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | PROFILE=/dev/null bash
fi

# Load nvm for the current shell session
if [ -s "$NVM_DIR/nvm.sh" ]; then
    \. "$NVM_DIR/nvm.sh"
else
    echo "ERROR: nvm installation not found in $NVM_DIR"
    exit 1
fi

# Install latest node only if the "node" alias is not already installed
if ! nvm version node >/dev/null 2>&1; then
    echo "Installing latest node..."
    nvm install node
else
    echo "Latest node already installed via nvm."
fi

# Ensure default alias points to latest node
nvm alias default node

echo "nvm setup complete."
