#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"

if is_macos; then
    echo "macOS detected. Azure CLI is managed via Homebrew (install/Brewfile)."
    exit 0
fi

if ! is_linux || ! command -v apt-get >/dev/null 2>&1; then
    echo "Azure CLI installer currently supports apt-based Linux/WSL environments only. Skipping."
    exit 0
fi

if package_is_installed azure-cli && { [ -f /etc/apt/sources.list.d/azure-cli.sources ] || [ -f /etc/apt/sources.list.d/azure-cli.list ]; }; then
    echo "Azure CLI is already installed and the apt repository is configured."
    exit 0
fi

source_versions "$SCRIPT_DIR"

AZURE_CLI_INSTALLER_SHA="${AZURE_CLI_APT_INSTALLER_SHA256:-}"
if [ -z "$AZURE_CLI_INSTALLER_SHA" ]; then
    echo "Missing checksum for Azure CLI apt installer. Run scripts/bump-versions.sh to refresh install/versions.env."
    exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

INSTALLER_URL="https://aka.ms/InstallAzureCLIDeb"
INSTALLER_PATH="$TMP_DIR/install-azure-cli.sh"

echo "Installing Azure CLI..."
download_and_verify "$INSTALLER_URL" "$INSTALLER_PATH" "$AZURE_CLI_INSTALLER_SHA" "Azure CLI apt installer"
chmod +x "$INSTALLER_PATH"
sudo env PATH="$PATH" bash "$INSTALLER_PATH" -y

if ! command -v az >/dev/null 2>&1; then
    echo "Azure CLI installer completed but 'az' is not available in PATH."
    exit 1
fi

echo "Azure CLI installation complete."
