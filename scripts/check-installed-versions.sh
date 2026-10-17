#!/bin/bash

# Verify that an apt-based bootstrap installed every pinned tool at (or above)
# its pin. Used by CI after ./bootstrap.sh; also handy locally.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../install/lib/helpers.sh
source "$ROOT_DIR/install/lib/helpers.sh"
source_versions "$ROOT_DIR/install"

failed=0
check() {
    if ! pinned_version_satisfied "$@"; then
        echo "FAIL: $(basename "$2") does not satisfy $1" >&2
        failed=1
    fi
}

arch="$(get_arch)"
for tool in "${PINNED_RELEASES[@]}"; do
    release_info "$tool" "$arch"
    read -r -a candidates <<<"$RELEASE_COMMANDS"
    case "$RELEASE_KIND" in
        tar | zip | bin) candidates+=("$RELEASE_DEST/${RELEASE_BINS%% *}") ;;
        appimage | source) candidates+=("/usr/local/bin/${candidates[0]}") ;;
    esac
    check "$RELEASE_VERSION" "${candidates[@]}"
done

MISE_BIN="$(resolve_mise_bin)"
check "$NODE_VERSION" "$(cd "$HOME" && "$MISE_BIN" which node)"
check "$GO_VERSION" "$(cd "$HOME" && "$MISE_BIN" which go)"

# Capture first: grep -q exiting early would fail the pipe under pipefail.
gh_policy="$(apt-cache policy gh)"
if ! grep -q 'cli.github.com' <<<"$gh_policy"; then
    echo "FAIL: gh is not installed from cli.github.com" >&2
    failed=1
fi

if [ "$failed" -ne 0 ]; then
    exit 1
fi
echo "All pinned tools are installed at their pinned versions."
