#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"
source_versions "$SCRIPT_DIR"

echo "Installing mise and the default language runtimes..."

for pin in MISE_VERSION NODE_VERSION GO_VERSION; do
    if [ -z "${!pin:-}" ]; then
        echo "$pin is missing. Run scripts/bump-versions.sh to refresh install/versions.env."
        exit 1
    fi
done

# Use global defaults only: ignore any project mise.toml in the caller's directory.
cd "$HOME"

if is_macos; then
    : # Homebrew installs mise from install/Brewfile.
elif command -v pacman >/dev/null 2>&1; then
    command -v mise >/dev/null 2>&1 || pacman_install mise
else
    install_release mise
fi

if ! MISE_BIN="$(resolve_mise_bin)"; then
    echo "mise not found. On macOS, run install/macos.sh (Homebrew bundle) first."
    exit 1
fi

# Pinned global defaults; a project's own mise.toml overrides them per directory.
# mise verifies the Node and Go downloads against the upstream checksums.
export MISE_YES=1
"$MISE_BIN" use --global "node@${NODE_VERSION}" "go@${GO_VERSION}"

# Extra global npm CLIs shared across machines (see install/npm-globals.txt).
mise_install_npm_tools npm-globals <"$SCRIPT_DIR/npm-globals.txt"

echo "mise runtimes ready: $("$MISE_BIN" exec -- node --version), $("$MISE_BIN" exec -- go version | awk '{print $3}')."
