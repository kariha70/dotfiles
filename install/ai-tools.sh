#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"
source_versions "$SCRIPT_DIR"

echo "Installing AI coding tools (Herdr, Codex, Claude Code, GitHub Copilot, Pi)..."

if is_macos; then
    echo "macOS detected. Homebrew manages AI coding tools except GitHub Copilot CLI, which mise installs from npm."
else
    ensure_local_bin

    if ! pinned_version_satisfied "${HERDR_VERSION:-}" herdr "$HOME/.local/bin/herdr"; then
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
        HERDR_URL="https://github.com/herdrdev/herdr/releases/download/v${HERDR_VERSION}/${HERDR_ASSET}"
        HERDR_TMP="$(mktemp /tmp/herdr.XXXXXX)"
        trap 'rm -f "$HERDR_TMP"' EXIT

        download_and_verify "$HERDR_URL" "$HERDR_TMP" "$HERDR_EXPECTED_SHA" "Herdr (${ARCH})"
        install -m 0755 "$HERDR_TMP" "$HOME/.local/bin/herdr"
        echo "Herdr installed."
    fi
fi

# The npm-based CLIs are mise tools, so they survive Node.js version changes
# and need no `npm install -g`. Claude Code's install script fetches its native
# binary, so it is allowed to run. On macOS, Homebrew provides Codex, Claude
# Code, and Pi (install/Brewfile); only GitHub Copilot CLI comes from npm.
if is_macos; then
    mise_install_npm_tools ai-tools <<'EOF_TOOLS'
@github/copilot
EOF_TOOLS
else
    mise_install_npm_tools ai-tools <<'EOF_TOOLS'
@openai/codex
@anthropic-ai/claude-code allow-builds
@github/copilot
@earendil-works/pi-coding-agent
EOF_TOOLS
fi

MISE_BIN="$(resolve_mise_bin)"
eval "$("$MISE_BIN" env -s bash)"
for command_name in codex claude copilot pi; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "AI tool installation completed, but '$command_name' is not on PATH."
        exit 1
    fi
done

echo "AI coding tools installation complete."
