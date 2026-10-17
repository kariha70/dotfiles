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
    install_release herdr
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
eval "$(cd "$HOME" && "$MISE_BIN" env -s bash)"
for command_name in codex claude copilot pi; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "AI tool installation completed, but '$command_name' is not on PATH."
        exit 1
    fi
done

echo "AI coding tools installation complete."
