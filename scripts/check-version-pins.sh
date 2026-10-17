#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/install/versions.env"
POWERSHELL_FILE="$ROOT_DIR/install/versions.ps1"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
    echo "Version pin validation failed: $*" >&2
    exit 1
}

[ -f "$ENV_FILE" ] || fail "missing $ENV_FILE"
[ -f "$POWERSHELL_FILE" ] || fail "missing $POWERSHELL_FILE"

awk -F= '
    /^[[:space:]]*(#|$)/ { next }
    /^[A-Za-z0-9_]+=/ { print; next }
    { exit 1 }
' "$ENV_FILE" >"$TMP_DIR/env.map" || fail "invalid line in versions.env"

sed -n "s/^    \([A-Za-z0-9_][A-Za-z0-9_]*\) = '\(.*\)'$/\1=\2/p" \
    "$POWERSHELL_FILE" >"$TMP_DIR/powershell.map"

for map in "$TMP_DIR/env.map" "$TMP_DIR/powershell.map"; do
    duplicate="$(cut -d= -f1 "$map" | sort | uniq -d | head -n 1)"
    [ -z "$duplicate" ] || fail "duplicate key $duplicate in $(basename "$map")"
done

if ! diff -u "$TMP_DIR/env.map" "$TMP_DIR/powershell.map"; then
    fail "install/versions.ps1 is not synchronized with install/versions.env; run pwsh -File scripts/bump-versions.ps1"
fi

# shellcheck source=/dev/null
source "$ENV_FILE"
# shellcheck source=../install/lib/releases.sh
source "$ROOT_DIR/install/lib/releases.sh"

# Every pinned release needs a version and a checksum per architecture.
sha_pins=()
version_pins=(NODE_VERSION GO_VERSION HERDR_WINDOWS_PREVIEW_TAG HERDR_WINDOWS_ASSET)
for tool in "${PINNED_RELEASES[@]}"; do
    upper="$(printf '%s' "$tool" | tr '[:lower:]' '[:upper:]')"
    version_pins+=("${upper}_VERSION")
    for arch in $(release_arches "$tool"); do
        sha_pins+=("${upper}_SHA256_${arch}")
    done
done

sha_pins+=(
    HERDR_WINDOWS_BINARY_SHA256_x86_64
    RUSTUP_INSTALLER_SHA256
    UV_INSTALLER_SHA256
    BUN_INSTALLER_SHA256
    HOMEBREW_INSTALLER_SHA256
    AZURE_CLI_APT_INSTALLER_SHA256
    GH_APT_KEYRING_SHA256
    MESLO_REGULAR_TTF_SHA256
    MESLO_BOLD_TTF_SHA256
    MESLO_ITALIC_TTF_SHA256
    MESLO_BOLD_ITALIC_TTF_SHA256
)

git_pins=(
    OHMYZSH_REF
    ZSH_AUTOSUGGESTIONS_REF
    ZSH_SYNTAX_HIGHLIGHTING_REF
    POWERLEVEL10K_REF
    POWERLEVEL10K_MEDIA_REF
)

for name in "${sha_pins[@]}"; do
    value="${!name:-}"
    [[ "$value" =~ ^[a-f0-9]{64}$ ]] || fail "$name must be a lowercase SHA256 digest"
done

for name in "${git_pins[@]}"; do
    value="${!name:-}"
    [[ "$value" =~ ^[a-f0-9]{40}$ ]] || fail "$name must be a full lowercase Git commit ID"
done

for name in "${version_pins[@]}"; do
    [ -n "${!name:-}" ] || fail "$name is missing"
    case "$name" in
        HERDR_WINDOWS_*) ;;
        *) [[ "${!name}" != v* ]] || fail "$name must not start with \"v\"" ;;
    esac
done

case "$HERDR_WINDOWS_ASSET" in
    herdr-windows-x86_64.exe | herdr-windows-x86_64.zip) ;;
    *) fail "HERDR_WINDOWS_ASSET must name a supported Herdr Windows asset" ;;
esac

for name in EZA_KEY_FINGERPRINT GIT_CORE_PPA_KEY_FINGERPRINT; do
    [[ "${!name:-}" =~ ^[A-F0-9]{40}$ ]] || \
        fail "$name must be a full uppercase GPG fingerprint"
done

echo "Version pins are complete, valid, and synchronized."
