#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HELPERS="$SCRIPT_DIR/lib/helpers.sh"
if [ -f "$HELPERS" ]; then
    # shellcheck source=/dev/null
    source "$HELPERS"
fi
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
    INSTALLER_PATH="$(mktemp /tmp/nvm-install.XXXXXX.sh)"
    trap 'rm -f "$INSTALLER_PATH"' EXIT
    curl -fLsS "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" -o "$INSTALLER_PATH"
    verify_sha256 "$INSTALLER_PATH" "$EXPECTED_NVM_SHA" "nvm installer"
    # We use PROFILE=/dev/null to prevent the install script from modifying .bashrc/.zshrc
    # because we manage those files ourselves.
    PROFILE=/dev/null bash "$INSTALLER_PATH"
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
