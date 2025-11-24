#!/bin/bash

set -e

export NVM_DIR="$HOME/.nvm"

echo "Installing nvm..."

# Install nvm
# We use PROFILE=/dev/null to prevent the install script from modifying .bashrc/.zshrc
# because we manage those files ourselves.
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | PROFILE=/dev/null bash

# Load nvm immediately to install node
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "Installing latest node..."
nvm install node
nvm alias default node

echo "nvm and node installed."
