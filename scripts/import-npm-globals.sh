#!/bin/bash

# One-time migration helper: copy the global npm packages installed under nvm
# (or any `npm root -g` directory passed as arguments) into
# install/npm-globals.txt, so mise installs them on every machine.
# Packages already declared, npm itself, corepack, and the AI CLIs managed by
# install/ai-tools.sh are skipped. Review and commit the result.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIST_FILE="$ROOT_DIR/install/npm-globals.txt"

if [ "$#" -gt 0 ]; then
    MODULE_DIRS=("$@")
else
    MODULE_DIRS=("${NVM_DIR:-$HOME/.nvm}"/versions/node/*/lib/node_modules)
fi

SKIP_PACKAGES=(
    npm
    corepack
    @openai/codex
    @anthropic-ai/claude-code
    @github/copilot
    @earendil-works/pi-coding-agent
)

is_listed() {
    local pkg="$1"
    awk -v pkg="$pkg" '!/^[[:space:]]*#/ && $1 == pkg { found = 1 } END { exit !found }' "$LIST_FILE"
}

added=0
for module_dir in "${MODULE_DIRS[@]}"; do
    [ -d "$module_dir" ] || continue
    for entry in "$module_dir"/* "$module_dir"/@*/*; do
        [ -d "$entry" ] || continue
        pkg="${entry#"$module_dir"/}"
        case "$pkg" in
            @*/*) ;;
            @*) continue ;;
        esac
        for skip in "${SKIP_PACKAGES[@]}"; do
            [ "$pkg" = "$skip" ] && continue 2
        done
        if ! is_listed "$pkg"; then
            printf '%s\n' "$pkg" >>"$LIST_FILE"
            echo "Added $pkg"
            added=$((added + 1))
        fi
    done
done

echo "Added $added package(s) to $LIST_FILE."
if [ "$added" -gt 0 ]; then
    echo "Append 'allow-builds' to any package that needs its install scripts, then rerun install/mise.sh."
fi
