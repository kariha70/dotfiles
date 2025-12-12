#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSIONS_FILE="$ROOT_DIR/install/versions.env"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing required command: $1"
        exit 1
    fi
}

require_cmd curl
require_cmd jq
require_cmd sha256sum

fetch_sha() {
    local url="$1" dest="$2"
    curl -fLs "$url" -o "$dest"
    sha256sum "$dest" | awk '{print $1}'
}

latest_tag() {
    local repo="$1"
    curl -s "https://api.github.com/repos/${repo}/releases/latest" | jq -r '.tag_name'
}

echo "Refreshing pinned versions and checksums..."

# nvm
nvm_tag="${NVM_VERSION_OVERRIDE:-$(latest_tag "nvm-sh/nvm")}"
if [ -z "$nvm_tag" ] || [ "$nvm_tag" = "null" ]; then
    echo "Could not determine latest nvm release tag."
    exit 1
fi
nvm_sha=$(fetch_sha "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_tag}/install.sh" "$TMP_DIR/nvm-install.sh")

# lazygit
lazygit_tag="${LAZYGIT_VERSION_OVERRIDE:-$(latest_tag "jesseduffield/lazygit")}"
if [ -z "$lazygit_tag" ] || [ "$lazygit_tag" = "null" ]; then
    echo "Could not determine latest lazygit release tag."
    exit 1
fi
lazygit_version="${lazygit_tag#v}"
lazygit_sha_x86=$(fetch_sha "https://github.com/jesseduffield/lazygit/releases/download/${lazygit_tag}/lazygit_${lazygit_version}_Linux_x86_64.tar.gz" "$TMP_DIR/lazygit_x86_64.tar.gz")
lazygit_sha_arm64=$(fetch_sha "https://github.com/jesseduffield/lazygit/releases/download/${lazygit_tag}/lazygit_${lazygit_version}_Linux_arm64.tar.gz" "$TMP_DIR/lazygit_arm64.tar.gz")

# git-delta
delta_tag="${DELTA_VERSION_OVERRIDE:-$(latest_tag "dandavison/delta")}"
if [ -z "$delta_tag" ] || [ "$delta_tag" = "null" ]; then
    echo "Could not determine latest git-delta release tag."
    exit 1
fi
delta_version="${delta_tag#v}"
delta_sha_amd64=$(fetch_sha "https://github.com/dandavison/delta/releases/download/${delta_version}/git-delta_${delta_version}_amd64.deb" "$TMP_DIR/git-delta_${delta_version}_amd64.deb")
delta_sha_arm64=$(fetch_sha "https://github.com/dandavison/delta/releases/download/${delta_version}/git-delta_${delta_version}_arm64.deb" "$TMP_DIR/git-delta_${delta_version}_arm64.deb")

# glow
glow_tag="${GLOW_VERSION_OVERRIDE:-$(latest_tag "charmbracelet/glow")}"
if [ -z "$glow_tag" ] || [ "$glow_tag" = "null" ]; then
    echo "Could not determine latest glow release tag."
    exit 1
fi
glow_version="${glow_tag#v}"
glow_sha_amd64=$(fetch_sha "https://github.com/charmbracelet/glow/releases/download/${glow_tag}/glow_${glow_version}_amd64.deb" "$TMP_DIR/glow_${glow_version}_amd64.deb")
glow_sha_arm64=$(fetch_sha "https://github.com/charmbracelet/glow/releases/download/${glow_tag}/glow_${glow_version}_arm64.deb" "$TMP_DIR/glow_${glow_version}_arm64.deb")

# fastfetch
fastfetch_tag="${FASTFETCH_VERSION_OVERRIDE:-$(latest_tag "fastfetch-cli/fastfetch")}"
if [ -z "$fastfetch_tag" ] || [ "$fastfetch_tag" = "null" ]; then
    echo "Could not determine latest fastfetch release tag."
    exit 1
fi
fastfetch_sha_linux_amd64=$(fetch_sha "https://github.com/fastfetch-cli/fastfetch/releases/download/${fastfetch_tag}/fastfetch-linux-amd64.deb" "$TMP_DIR/fastfetch-linux-amd64.deb")
fastfetch_sha_linux_aarch64=$(fetch_sha "https://github.com/fastfetch-cli/fastfetch/releases/download/${fastfetch_tag}/fastfetch-linux-aarch64.deb" "$TMP_DIR/fastfetch-linux-aarch64.deb")

# yazi
yazi_tag="${YAZI_VERSION_OVERRIDE:-$(latest_tag "sxyazi/yazi")}"
if [ -z "$yazi_tag" ] || [ "$yazi_tag" = "null" ]; then
    echo "Could not determine latest yazi release tag."
    exit 1
fi
yazi_sha_x86=$(fetch_sha "https://github.com/sxyazi/yazi/releases/download/${yazi_tag}/yazi-x86_64-unknown-linux-gnu.zip" "$TMP_DIR/yazi-x86_64-unknown-linux-gnu.zip")
yazi_sha_arm64=$(fetch_sha "https://github.com/sxyazi/yazi/releases/download/${yazi_tag}/yazi-aarch64-unknown-linux-gnu.zip" "$TMP_DIR/yazi-aarch64-unknown-linux-gnu.zip")

# atuin
atuin_tag="${ATUIN_VERSION_OVERRIDE:-$(latest_tag "atuinsh/atuin")}"
if [ -z "$atuin_tag" ] || [ "$atuin_tag" = "null" ]; then
    echo "Could not determine latest atuin release tag."
    exit 1
fi
atuin_sha_x86=$(fetch_sha "https://github.com/atuinsh/atuin/releases/download/${atuin_tag}/atuin-x86_64-unknown-linux-gnu.tar.gz" "$TMP_DIR/atuin-x86_64-unknown-linux-gnu.tar.gz")
atuin_sha_arm64=$(fetch_sha "https://github.com/atuinsh/atuin/releases/download/${atuin_tag}/atuin-aarch64-unknown-linux-gnu.tar.gz" "$TMP_DIR/atuin-aarch64-unknown-linux-gnu.tar.gz")

# zoxide installer
zoxide_sha=$(fetch_sha "https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh" "$TMP_DIR/zoxide-install.sh")

# uv installer
uv_sha=$(fetch_sha "https://astral.sh/uv/install.sh" "$TMP_DIR/uv-install.sh")

# MesloLGS fonts
font_base="https://github.com/romkatv/powerlevel10k-media/raw/master"
meslo_regular_sha=$(fetch_sha "$font_base/MesloLGS%20NF%20Regular.ttf" "$TMP_DIR/MesloLGS NF Regular.ttf")
meslo_bold_sha=$(fetch_sha "$font_base/MesloLGS%20NF%20Bold.ttf" "$TMP_DIR/MesloLGS NF Bold.ttf")
meslo_italic_sha=$(fetch_sha "$font_base/MesloLGS%20NF%20Italic.ttf" "$TMP_DIR/MesloLGS NF Italic.ttf")
meslo_bold_italic_sha=$(fetch_sha "$font_base/MesloLGS%20NF%20Bold%20Italic.ttf" "$TMP_DIR/MesloLGS NF Bold Italic.ttf")

cat >"$VERSIONS_FILE" <<EOF
# Auto-generated by scripts/bump-versions.sh
# $(date -u +"%Y-%m-%dT%H:%M:%SZ")

NVM_VERSION=${nvm_tag}
NVM_INSTALLER_SHA256=${nvm_sha}

LAZYGIT_VERSION=${lazygit_version}
LAZYGIT_TAR_SHA256_x86_64=${lazygit_sha_x86}
LAZYGIT_TAR_SHA256_arm64=${lazygit_sha_arm64}

DELTA_VERSION=${delta_version}
DELTA_DEB_SHA256_amd64=${delta_sha_amd64}
DELTA_DEB_SHA256_arm64=${delta_sha_arm64}

GLOW_VERSION=${glow_tag}
GLOW_DEB_SHA256_amd64=${glow_sha_amd64}
GLOW_DEB_SHA256_arm64=${glow_sha_arm64}

FASTFETCH_VERSION=${fastfetch_tag}
FASTFETCH_DEB_SHA256_linux_amd64=${fastfetch_sha_linux_amd64}
FASTFETCH_DEB_SHA256_linux_aarch64=${fastfetch_sha_linux_aarch64}

YAZI_VERSION=${yazi_tag}
YAZI_ZIP_SHA256_x86_64_unknown_linux_gnu=${yazi_sha_x86}
YAZI_ZIP_SHA256_aarch64_unknown_linux_gnu=${yazi_sha_arm64}

ATUIN_VERSION=${atuin_tag}
ATUIN_TAR_SHA256_x86_64_unknown_linux_gnu=${atuin_sha_x86}
ATUIN_TAR_SHA256_aarch64_unknown_linux_gnu=${atuin_sha_arm64}

ZOXIDE_INSTALLER_SHA256=${zoxide_sha}

UV_INSTALLER_SHA256=${uv_sha}

MESLO_REGULAR_TTF_SHA256=${meslo_regular_sha}
MESLO_BOLD_TTF_SHA256=${meslo_bold_sha}
MESLO_ITALIC_TTF_SHA256=${meslo_italic_sha}
MESLO_BOLD_ITALIC_TTF_SHA256=${meslo_bold_italic_sha}
EOF

echo "Updated $VERSIONS_FILE:"
cat "$VERSIONS_FILE"
