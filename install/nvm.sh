#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VERSIONS_FILE="${VERSIONS_FILE:-$SCRIPT_DIR/versions.env}"
if [ -f "$VERSIONS_FILE" ]; then
    # shellcheck source=/dev/null
    source "$VERSIONS_FILE"
else
    echo "versions.env not found at $VERSIONS_FILE. Run scripts/bump-versions.sh to generate it."
    exit 1
fi

export NVM_DIR="$HOME/.nvm"
NVM_DEFAULT_ALIAS="${NVM_DEFAULT_ALIAS:-lts/*}"
NVM_VERSION="${NVM_VERSION:-}"
EXPECTED_NVM_SHA="${NVM_INSTALLER_SHA256:-}"

if [ -z "$NVM_VERSION" ] || [ -z "$EXPECTED_NVM_SHA" ]; then
    echo "NVM_VERSION or NVM_INSTALLER_SHA256 is missing. Run scripts/bump-versions.sh to refresh install/versions.env."
    exit 1
fi

# Install nvm only if it is not already present
if [ -s "$NVM_DIR/nvm.sh" ]; then
    echo "nvm is already installed."
else
    echo "Installing nvm..."
    INSTALLER_PATH=/tmp/nvm-install.sh
    curl -fLo "$INSTALLER_PATH" "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh"
    INSTALLER_SHA=$(sha256sum "$INSTALLER_PATH" | awk '{print $1}')
    if [ "$INSTALLER_SHA" != "$EXPECTED_NVM_SHA" ]; then
        echo "Checksum mismatch for nvm installer."
        echo "Expected: $EXPECTED_NVM_SHA"
        echo "Actual:   $INSTALLER_SHA"
        echo "Update install/versions.env with scripts/bump-versions.sh if a new release is available."
        rm -f "$INSTALLER_PATH"
        exit 1
    fi
    # We use PROFILE=/dev/null to prevent the install script from modifying .bashrc/.zshrc
    # because we manage those files ourselves.
    PROFILE=/dev/null bash "$INSTALLER_PATH"
    rm -f "$INSTALLER_PATH"
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
