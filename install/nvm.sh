#!/bin/bash

set -e

export NVM_DIR="$HOME/.nvm"
NVM_DEFAULT_ALIAS="${NVM_DEFAULT_ALIAS:-lts/*}"

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
    # shellcheck source=/dev/null
    \. "$NVM_DIR/nvm.sh"
else
    echo "ERROR: nvm installation not found in $NVM_DIR"
    exit 1
fi

# Install default Node (LTS by default) only if the alias is not already installed
if ! nvm version "$NVM_DEFAULT_ALIAS" >/dev/null 2>&1; then
    echo "Installing Node version ($NVM_DEFAULT_ALIAS)..."
    nvm install "$NVM_DEFAULT_ALIAS"
else
    echo "Node alias $NVM_DEFAULT_ALIAS already installed via nvm."
fi

# Ensure default alias points to the chosen line
nvm alias default "$NVM_DEFAULT_ALIAS"

echo "nvm setup complete."
