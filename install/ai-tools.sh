#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"
source_versions "$SCRIPT_DIR"

echo "Installing AI coding tools (Herdr, Codex, Claude Code, GitHub Copilot)..."

if is_macos; then
    echo "macOS detected. AI coding tools are managed via Homebrew (install/Brewfile)."
    exit 0
fi

ensure_local_bin

if ! command -v herdr >/dev/null 2>&1; then
    if [ -z "${HERDR_VERSION:-}" ]; then
        echo "HERDR_VERSION is missing. Run scripts/bump-versions.sh."
        exit 1
    fi

    ARCH="$(get_arch)"
    HERDR_SHA_VAR="HERDR_BINARY_SHA256_${ARCH}"
    HERDR_EXPECTED_SHA="${!HERDR_SHA_VAR:-}"
    case "$ARCH" in
        x86_64) HERDR_ASSET="herdr-linux-x86_64" ;;
        arm64) HERDR_ASSET="herdr-linux-aarch64" ;;
    esac
    HERDR_URL="https://github.com/ogulcancelik/herdr/releases/download/v${HERDR_VERSION}/${HERDR_ASSET}"
    HERDR_TMP="$(mktemp /tmp/herdr.XXXXXX)"
    trap 'rm -f "$HERDR_TMP"' EXIT

    download_and_verify "$HERDR_URL" "$HERDR_TMP" "$HERDR_EXPECTED_SHA" "Herdr (${ARCH})"
    install -m 0755 "$HERDR_TMP" "$HOME/.local/bin/herdr"
    echo "Herdr installed."
else
    echo "Herdr is already installed."
fi

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck source=/dev/null
    \. "$NVM_DIR/nvm.sh"
    nvm use default >/dev/null
fi

if ! command -v npm >/dev/null 2>&1; then
    echo "npm is required to install Codex, Claude Code, and GitHub Copilot CLI."
    echo "Run install/nvm.sh first, then rerun this installer."
    exit 1
fi

install_npm_cli() {
    local command_name="$1" package_name="$2" label="$3"
    if command -v "$command_name" >/dev/null 2>&1; then
        echo "$label is already installed."
        return 0
    fi

    echo "Installing $label..."
    npm_config_ignore_scripts=false npm install --global "$package_name"
    command -v "$command_name" >/dev/null 2>&1 || {
        echo "$label installation completed, but '$command_name' is not on PATH."
        exit 1
    }
}

install_npm_cli codex @openai/codex "Codex CLI"
install_npm_cli claude @anthropic-ai/claude-code "Claude Code"
install_npm_cli copilot @github/copilot "GitHub Copilot CLI"

echo "AI coding tools installation complete."
