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

sha_pins=(
    NVM_INSTALLER_SHA256
    NEOVIM_APPIMAGE_SHA256_x86_64
    NEOVIM_APPIMAGE_SHA256_arm64
    LAZYGIT_TAR_SHA256_x86_64
    LAZYGIT_TAR_SHA256_arm64
    DELTA_DEB_SHA256_amd64
    DELTA_DEB_SHA256_arm64
    GLOW_DEB_SHA256_amd64
    GLOW_DEB_SHA256_arm64
    FASTFETCH_DEB_SHA256_linux_amd64
    FASTFETCH_DEB_SHA256_linux_aarch64
    YAZI_ZIP_SHA256_x86_64_unknown_linux_gnu
    YAZI_ZIP_SHA256_aarch64_unknown_linux_gnu
    ATUIN_TAR_SHA256_x86_64_unknown_linux_gnu
    ATUIN_TAR_SHA256_aarch64_unknown_linux_gnu
    ZOXIDE_INSTALLER_SHA256
    RUSTUP_INSTALLER_SHA256
    UV_INSTALLER_SHA256
    BUN_INSTALLER_SHA256
    HERDR_BINARY_SHA256_x86_64
    HERDR_BINARY_SHA256_arm64
    HERDR_WINDOWS_BINARY_SHA256_x86_64
    HOMEBREW_INSTALLER_SHA256
    AZURE_CLI_APT_INSTALLER_SHA256
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

version_pins=(
    NVM_VERSION
    NEOVIM_VERSION
    LAZYGIT_VERSION
    DELTA_VERSION
    GLOW_VERSION
    FASTFETCH_VERSION
    YAZI_VERSION
    ATUIN_VERSION
    HERDR_VERSION
    HERDR_WINDOWS_PREVIEW_TAG
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
done

[[ "${EZA_KEY_FINGERPRINT:-}" =~ ^[A-F0-9]{40}$ ]] || \
    fail "EZA_KEY_FINGERPRINT must be a full uppercase GPG fingerprint"

echo "Version pins are complete, valid, and synchronized."
