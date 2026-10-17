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

MISE_BIN="$HOME/.local/bin/mise"

# Use global defaults only: ignore any project mise.toml in the caller's directory.
cd "$HOME"

if is_macos; then
    # Homebrew installs mise from install/Brewfile.
    if ! MISE_BIN="$(resolve_mise_bin)"; then
        echo "mise not found. Run install/macos.sh (Homebrew bundle) first."
        exit 1
    fi
elif command -v pacman >/dev/null 2>&1; then
    if ! command -v mise >/dev/null 2>&1; then
        pacman_install mise
    fi
    MISE_BIN="$(command -v mise)"
elif ! pinned_version_satisfied "$MISE_VERSION" "$MISE_BIN"; then
    ARCH="$(get_arch)"
    case "$ARCH" in
        x86_64) MISE_ARCH="x64" ;;
        arm64) MISE_ARCH="arm64" ;;
    esac

    EXPECTED_VAR="MISE_BINARY_SHA256_${ARCH}"
    EXPECTED_MISE_SHA="${!EXPECTED_VAR:-}"
    MISE_ASSET="mise-v${MISE_VERSION}-linux-${MISE_ARCH}"

    TMP_MISE="$(mktemp /tmp/mise.XXXXXX)"
    trap 'rm -f "$TMP_MISE"' EXIT
    download_and_verify \
        "https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/${MISE_ASSET}" \
        "$TMP_MISE" \
        "$EXPECTED_MISE_SHA" \
        "mise (${ARCH})"
    ensure_local_bin
    install -m 0755 "$TMP_MISE" "$MISE_BIN"
    echo "mise ${MISE_VERSION} installed to $MISE_BIN."
fi

# Pinned global defaults; a project's own mise.toml overrides them per directory.
# mise verifies the Node and Go downloads against the upstream checksums.
export MISE_YES=1
"$MISE_BIN" use --global "node@${NODE_VERSION}" "go@${GO_VERSION}"

# Extra global npm CLIs shared across machines (see install/npm-globals.txt).
mise_install_npm_tools npm-globals <"$SCRIPT_DIR/npm-globals.txt"

echo "mise runtimes ready: $("$MISE_BIN" exec -- node --version), $("$MISE_BIN" exec -- go version | awk '{print $3}')."
