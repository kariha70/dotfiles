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

echo "Installing lazygit..."

if command -v lazygit &> /dev/null; then
    echo "lazygit is already installed."
    exit 0
fi

if [ -z "${LAZYGIT_VERSION:-}" ]; then
    echo "LAZYGIT_VERSION is missing. Run scripts/bump-versions.sh to refresh install/versions.env."
    exit 1
fi

ARCH=$(uname -m)
case $ARCH in
    x86_64)
        LAZYGIT_ARCH="x86_64"
        ;;
    aarch64|arm64)
        LAZYGIT_ARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

EXPECTED_VAR="LAZYGIT_TAR_SHA256_${LAZYGIT_ARCH}"
EXPECTED_LAZYGIT_SHA="${!EXPECTED_VAR:-}"
if [ -z "$EXPECTED_LAZYGIT_SHA" ]; then
    echo "Missing checksum for ${LAZYGIT_ARCH} in install/versions.env (${EXPECTED_VAR}). Run scripts/bump-versions.sh."
    exit 1
fi

curl -fLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz"
LAZYGIT_SHA=$(sha256sum /tmp/lazygit.tar.gz | awk '{print $1}')
if [ "$LAZYGIT_SHA" != "$EXPECTED_LAZYGIT_SHA" ]; then
    echo "Checksum mismatch for lazygit tarball."
    echo "Expected: $EXPECTED_LAZYGIT_SHA"
    echo "Actual:   $LAZYGIT_SHA"
    echo "Update install/versions.env with scripts/bump-versions.sh if a new release is available."
    rm -f /tmp/lazygit.tar.gz
    exit 1
fi
tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
sudo install /tmp/lazygit /usr/local/bin
rm -f /tmp/lazygit /tmp/lazygit.tar.gz

echo "lazygit installed successfully."
