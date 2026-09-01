#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSIONS_FILE="${VERSIONS_FILE:-$ROOT_DIR/install/versions.env}"
POWERSHELL_VERSIONS_FILE="${POWERSHELL_VERSIONS_FILE:-$ROOT_DIR/install/versions.ps1}"
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
require_cmd git
require_cmd gpg

CURL_ARGS=(
    --fail
    --location
    --silent
    --show-error
    --retry 3
    --retry-delay 2
    --retry-all-errors
)

GITHUB_API_ARGS=(
    -H "User-Agent: dotfiles-bump-versions"
    -H "Accept: application/vnd.github+json"
)

if [ -n "${GITHUB_TOKEN:-${GH_TOKEN:-}}" ]; then
    GITHUB_API_ARGS+=( -H "Authorization: Bearer ${GITHUB_TOKEN:-${GH_TOKEN:-}}" )
fi

sha256_portable() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        echo "Missing required command: sha256sum or shasum" >&2
        exit 1
    fi
}

fetch_sha() {
    local url="$1" dest="$2" tmp sha
    tmp="${dest}.part"
    rm -f "$dest" "$tmp"

    if ! curl "${CURL_ARGS[@]}" "$url" -o "$tmp"; then
        rm -f "$tmp"
        return 1
    fi

    mv "$tmp" "$dest"

    if ! sha="$(sha256_portable "$dest")"; then
        rm -f "$dest"
        return 1
    fi

    printf '%s\n' "$sha"
}

github_api() {
    curl "${CURL_ARGS[@]}" "${GITHUB_API_ARGS[@]}" "$1"
}

url_exists() {
    curl "${CURL_ARGS[@]}" --head "$1" >/dev/null
}

gpg_fingerprint() {
    local key_file="$1" fingerprint
    fingerprint="$(gpg --batch --with-colons --import-options show-only --import "$key_file" 2>/dev/null | awk -F: '/^fpr:/ { print $10; exit }')"
    if [[ ! "$fingerprint" =~ ^[A-F0-9]{40}$ ]]; then
        echo "Could not determine GPG fingerprint for $key_file." >&2
        exit 1
    fi
    printf '%s\n' "$fingerprint"
}

latest_git_tag() {
    local repo="$1"
    git ls-remote --refs --sort='version:refname' --tags "https://github.com/${repo}.git" |
        awk 'END { sub(/^refs\/tags\//, "", $2); print $2 }'
}

latest_tag() {
    local repo="$1" tag

    tag="$(github_api "https://api.github.com/repos/${repo}/releases/latest" |
        jq -er '.tag_name | select(type == "string" and length > 0)' 2>/dev/null || true)"
    if [ -n "$tag" ] && [ "$tag" != "null" ]; then
        printf '%s\n' "$tag"
        return 0
    fi

    tag="$(latest_git_tag "$repo" || true)"
    if [ -n "$tag" ]; then
        echo "Warning: could not query GitHub releases API for ${repo}; using newest git tag ${tag}." >&2
        printf '%s\n' "$tag"
        return 0
    fi

    return 1
}

latest_release_with_assets() {
    local repo="$1" current_tag="$2"
    shift 2

    if [ "$#" -eq 0 ]; then
        echo "latest_release_with_assets requires at least one asset name." >&2
        exit 1
    fi

    local required_assets_json releases_json tag latest_seen_tag="" page=1 asset api_failed=0
    required_assets_json="$(printf '%s\n' "$@" | jq -R . | jq -s .)"

    while :; do
        if ! releases_json="$(github_api "https://api.github.com/repos/${repo}/releases?per_page=100&page=${page}")"; then
            api_failed=1
            break
        fi

        if [ "$(jq 'length' <<<"$releases_json")" -eq 0 ]; then
            break
        fi

        if [ -z "$latest_seen_tag" ]; then
            latest_seen_tag="$(jq -er '[ .[] | select(.draft | not) | select(.prerelease | not) | .tag_name ][0] // empty' <<<"$releases_json" 2>/dev/null || true)"
        fi

        tag="$(jq -er --argjson required "$required_assets_json" '
            [ .[] as $release
              | select($release.draft | not)
              | select($release.prerelease | not)
              | select($required | all(. as $name | any($release.assets[]?; .name == $name)))
              | $release.tag_name
            ][0] // empty
        ' <<<"$releases_json" 2>/dev/null || true)"

        if [ -n "$tag" ] && [ "$tag" != "null" ]; then
            if [ -n "$latest_seen_tag" ] && [ "$tag" != "$latest_seen_tag" ]; then
                echo "Warning: latest ${repo} release ${latest_seen_tag} is missing required assets; using ${tag}." >&2
            fi
            printf '%s\n' "$tag"
            return 0
        fi

        page=$((page + 1))
    done

    if [ -n "$current_tag" ]; then
        for asset in "$@"; do
            if ! url_exists "https://github.com/${repo}/releases/download/${current_tag}/${asset}"; then
                current_tag=""
                break
            fi
        done
    fi

    if [ -n "$current_tag" ]; then
        if [ "$api_failed" -eq 1 ]; then
            echo "Warning: could not query GitHub releases API for ${repo}; keeping existing pin ${current_tag}." >&2
        else
            echo "Warning: could not find a newer ${repo} release with the required assets; keeping existing pin ${current_tag}." >&2
        fi
        printf '%s\n' "$current_tag"
        return 0
    fi

    return 1
}

latest_head_ref() {
    local repo="$1"
    git ls-remote "https://github.com/${repo}.git" HEAD | awk 'NR == 1 { print $1 }'
}

resolve_git_ref() {
    local label="$1" repo="$2" current_ref="${3:-}" resolved_ref

    resolved_ref="$(latest_head_ref "$repo" || true)"
    if [ -n "$resolved_ref" ]; then
        printf '%s\n' "$resolved_ref"
        return 0
    fi

    if [ -n "$current_ref" ]; then
        echo "Warning: could not refresh ${label} ref; keeping existing pin ${current_ref}." >&2
        printf '%s\n' "$current_ref"
        return 0
    fi

    echo "Could not determine pinned ref for ${label}." >&2
    exit 1
}

echo "Refreshing pinned versions and checksums..."

if [ -f "$VERSIONS_FILE" ]; then
    # shellcheck source=/dev/null
    source "$VERSIONS_FILE"
fi

# nvm
nvm_tag="${NVM_VERSION_OVERRIDE:-$(latest_tag "nvm-sh/nvm")}"
if [ -z "$nvm_tag" ] || [ "$nvm_tag" = "null" ]; then
    echo "Could not determine latest nvm release tag."
    exit 1
fi
nvm_sha=$(fetch_sha "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_tag}/install.sh" "$TMP_DIR/nvm-install.sh")

# neovim
neovim_tag="${NEOVIM_VERSION_OVERRIDE:-$(latest_tag "neovim/neovim")}"
if [ -z "$neovim_tag" ] || [ "$neovim_tag" = "null" ]; then
    echo "Could not determine latest neovim release tag."
    exit 1
fi
neovim_sha_x86=$(fetch_sha "https://github.com/neovim/neovim/releases/download/${neovim_tag}/nvim-linux-x86_64.appimage" "$TMP_DIR/nvim-linux-x86_64.appimage")
neovim_sha_arm64=$(fetch_sha "https://github.com/neovim/neovim/releases/download/${neovim_tag}/nvim-linux-arm64.appimage" "$TMP_DIR/nvim-linux-arm64.appimage")

# lazygit
lazygit_tag="${LAZYGIT_VERSION_OVERRIDE:-$(latest_tag "jesseduffield/lazygit")}"
if [ -z "$lazygit_tag" ] || [ "$lazygit_tag" = "null" ]; then
    echo "Could not determine latest lazygit release tag."
    exit 1
fi
lazygit_version="${lazygit_tag#v}"
lazygit_sha_x86=$(fetch_sha "https://github.com/jesseduffield/lazygit/releases/download/${lazygit_tag}/lazygit_${lazygit_version}_Linux_x86_64.tar.gz" "$TMP_DIR/lazygit_x86_64.tar.gz")
lazygit_sha_arm64=$(fetch_sha "https://github.com/jesseduffield/lazygit/releases/download/${lazygit_tag}/lazygit_${lazygit_version}_Linux_arm64.tar.gz" "$TMP_DIR/lazygit_arm64.tar.gz")

# just
just_tag="${JUST_VERSION_OVERRIDE:-$(latest_tag "casey/just")}"
if [ -z "$just_tag" ] || [ "$just_tag" = "null" ]; then
    echo "Could not determine latest just release tag."
    exit 1
fi
just_version="${just_tag#v}"
just_sha_x86=$(fetch_sha "https://github.com/casey/just/releases/download/${just_tag}/just-${just_version}-x86_64-unknown-linux-musl.tar.gz" "$TMP_DIR/just-x86_64-unknown-linux-musl.tar.gz")
just_sha_arm64=$(fetch_sha "https://github.com/casey/just/releases/download/${just_tag}/just-${just_version}-aarch64-unknown-linux-musl.tar.gz" "$TMP_DIR/just-aarch64-unknown-linux-musl.tar.gz")

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
fastfetch_repo="fastfetch-cli/fastfetch"
fastfetch_amd64_asset="fastfetch-linux-amd64.deb"
fastfetch_aarch64_asset="fastfetch-linux-aarch64.deb"

if [ -n "${FASTFETCH_VERSION_OVERRIDE:-}" ]; then
    fastfetch_tag="$FASTFETCH_VERSION_OVERRIDE"
else
    fastfetch_tag="$(latest_release_with_assets "$fastfetch_repo" "${FASTFETCH_VERSION:-}" "$fastfetch_amd64_asset" "$fastfetch_aarch64_asset")"
fi

if [ -z "$fastfetch_tag" ] || [ "$fastfetch_tag" = "null" ]; then
    echo "Could not determine a fastfetch release with the required Debian assets."
    exit 1
fi

fastfetch_sha_linux_amd64="$(fetch_sha "https://github.com/${fastfetch_repo}/releases/download/${fastfetch_tag}/${fastfetch_amd64_asset}" "$TMP_DIR/${fastfetch_amd64_asset}")" || exit 1
fastfetch_sha_linux_aarch64="$(fetch_sha "https://github.com/${fastfetch_repo}/releases/download/${fastfetch_tag}/${fastfetch_aarch64_asset}" "$TMP_DIR/${fastfetch_aarch64_asset}")" || exit 1

# yazi
yazi_tag="${YAZI_VERSION_OVERRIDE:-$(latest_tag "sxyazi/yazi")}"
if [ -z "$yazi_tag" ] || [ "$yazi_tag" = "null" ]; then
    echo "Could not determine latest yazi release tag."
    exit 1
fi
yazi_sha_x86=$(fetch_sha "https://github.com/sxyazi/yazi/releases/download/${yazi_tag}/yazi-x86_64-unknown-linux-gnu.zip" "$TMP_DIR/yazi-x86_64-unknown-linux-gnu.zip")
yazi_sha_arm64=$(fetch_sha "https://github.com/sxyazi/yazi/releases/download/${yazi_tag}/yazi-aarch64-unknown-linux-gnu.zip" "$TMP_DIR/yazi-aarch64-unknown-linux-gnu.zip")

# superfile
superfile_tag="${SUPERFILE_VERSION_OVERRIDE:-$(latest_tag "yorukot/superfile")}"
if [ -z "$superfile_tag" ] || [ "$superfile_tag" = "null" ]; then
    echo "Could not determine latest superfile release tag."
    exit 1
fi
superfile_sha_amd64=$(fetch_sha "https://github.com/yorukot/superfile/releases/download/${superfile_tag}/superfile-linux-${superfile_tag}-amd64.tar.gz" "$TMP_DIR/superfile-linux-amd64.tar.gz")
superfile_sha_arm64=$(fetch_sha "https://github.com/yorukot/superfile/releases/download/${superfile_tag}/superfile-linux-${superfile_tag}-arm64.tar.gz" "$TMP_DIR/superfile-linux-arm64.tar.gz")

# atuin
atuin_tag="${ATUIN_VERSION_OVERRIDE:-$(latest_tag "atuinsh/atuin")}"
if [ -z "$atuin_tag" ] || [ "$atuin_tag" = "null" ]; then
    echo "Could not determine latest atuin release tag."
    exit 1
fi
atuin_sha_x86=$(fetch_sha "https://github.com/atuinsh/atuin/releases/download/${atuin_tag}/atuin-x86_64-unknown-linux-gnu.tar.gz" "$TMP_DIR/atuin-x86_64-unknown-linux-gnu.tar.gz")
atuin_sha_arm64=$(fetch_sha "https://github.com/atuinsh/atuin/releases/download/${atuin_tag}/atuin-aarch64-unknown-linux-gnu.tar.gz" "$TMP_DIR/atuin-aarch64-unknown-linux-gnu.tar.gz")

# herdr
herdr_repo="herdrdev/herdr"
herdr_tag="${HERDR_VERSION_OVERRIDE:-$(latest_tag "$herdr_repo")}"
if [ -z "$herdr_tag" ] || [ "$herdr_tag" = "null" ]; then
    echo "Could not determine latest Herdr release tag."
    exit 1
fi
herdr_version="${herdr_tag#v}"
herdr_sha_x86=$(fetch_sha "https://github.com/${herdr_repo}/releases/download/${herdr_tag}/herdr-linux-x86_64" "$TMP_DIR/herdr-linux-x86_64")
herdr_sha_arm64=$(fetch_sha "https://github.com/${herdr_repo}/releases/download/${herdr_tag}/herdr-linux-aarch64" "$TMP_DIR/herdr-linux-aarch64")

herdr_preview_manifest="$TMP_DIR/herdr-preview.json"
curl "${CURL_ARGS[@]}" "https://herdr.dev/preview.json" -o "$herdr_preview_manifest"
herdr_windows_url=$(jq -er '.assets["windows-x86_64"].url' "$herdr_preview_manifest")
herdr_windows_declared_sha=$(jq -er '.assets["windows-x86_64"].sha256' "$herdr_preview_manifest")
herdr_windows_preview_tag=$(basename "$(dirname "$herdr_windows_url")")
herdr_windows_asset=$(basename "$herdr_windows_url")
case "$herdr_windows_url" in
    "https://github.com/${herdr_repo}/releases/download/${herdr_windows_preview_tag}/herdr-windows-x86_64.exe" | \
        "https://github.com/${herdr_repo}/releases/download/${herdr_windows_preview_tag}/herdr-windows-x86_64.zip") ;;
    *)
        echo "Herdr Windows preview manifest contains an unexpected asset URL."
        exit 1
        ;;
esac
herdr_windows_sha=$(fetch_sha "$herdr_windows_url" "$TMP_DIR/$herdr_windows_asset")
if [ "$herdr_windows_sha" != "$herdr_windows_declared_sha" ]; then
    echo "Herdr Windows preview manifest checksum mismatch."
    exit 1
fi

# zoxide installer
zoxide_sha=$(fetch_sha "https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh" "$TMP_DIR/zoxide-install.sh")

# rustup installer
rustup_sha=$(fetch_sha "https://sh.rustup.rs" "$TMP_DIR/rustup-install.sh")

# uv installer
uv_sha=$(fetch_sha "https://astral.sh/uv/install.sh" "$TMP_DIR/uv-install.sh")

# Bun installer
bun_sha=$(fetch_sha "https://bun.sh/install" "$TMP_DIR/bun-install.sh")

# Homebrew installer
homebrew_installer_sha=$(fetch_sha "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" "$TMP_DIR/homebrew-install.sh")

# Azure CLI apt installer
azure_cli_apt_installer_sha=$(fetch_sha "https://aka.ms/InstallAzureCLIDeb" "$TMP_DIR/install-azure-cli.sh")

# eza apt repository signing key
curl "${CURL_ARGS[@]}" "https://raw.githubusercontent.com/eza-community/eza/main/deb.asc" -o "$TMP_DIR/eza.asc"
eza_key_fingerprint=$(gpg_fingerprint "$TMP_DIR/eza.asc")

# Pinned git refs
ohmyzsh_ref="${OHMYZSH_REF_OVERRIDE:-$(resolve_git_ref "Oh My Zsh" "ohmyzsh/ohmyzsh" "${OHMYZSH_REF:-}")}"
zsh_autosuggestions_ref="${ZSH_AUTOSUGGESTIONS_REF_OVERRIDE:-$(resolve_git_ref "zsh-autosuggestions" "zsh-users/zsh-autosuggestions" "${ZSH_AUTOSUGGESTIONS_REF:-}")}"
zsh_syntax_highlighting_ref="${ZSH_SYNTAX_HIGHLIGHTING_REF_OVERRIDE:-$(resolve_git_ref "zsh-syntax-highlighting" "zsh-users/zsh-syntax-highlighting" "${ZSH_SYNTAX_HIGHLIGHTING_REF:-}")}"
powerlevel10k_ref="${POWERLEVEL10K_REF_OVERRIDE:-$(resolve_git_ref "Powerlevel10k" "romkatv/powerlevel10k" "${POWERLEVEL10K_REF:-}")}"
powerlevel10k_media_ref="${POWERLEVEL10K_MEDIA_REF_OVERRIDE:-$(resolve_git_ref "powerlevel10k-media" "romkatv/powerlevel10k-media" "${POWERLEVEL10K_MEDIA_REF:-}")}"

# MesloLGS fonts
font_base="https://raw.githubusercontent.com/romkatv/powerlevel10k-media/${powerlevel10k_media_ref}"
meslo_regular_sha=$(fetch_sha "$font_base/MesloLGS%20NF%20Regular.ttf" "$TMP_DIR/MesloLGS NF Regular.ttf")
meslo_bold_sha=$(fetch_sha "$font_base/MesloLGS%20NF%20Bold.ttf" "$TMP_DIR/MesloLGS NF Bold.ttf")
meslo_italic_sha=$(fetch_sha "$font_base/MesloLGS%20NF%20Italic.ttf" "$TMP_DIR/MesloLGS NF Italic.ttf")
meslo_bold_italic_sha=$(fetch_sha "$font_base/MesloLGS%20NF%20Bold%20Italic.ttf" "$TMP_DIR/MesloLGS NF Bold Italic.ttf")

generated_versions="$TMP_DIR/versions.env"
generated_powershell_versions="$TMP_DIR/versions.ps1"

cat >"$generated_versions" <<EOF
# Auto-generated by scripts/bump-versions.sh
# $(date -u +"%Y-%m-%dT%H:%M:%SZ")

NVM_VERSION=${nvm_tag}
NVM_INSTALLER_SHA256=${nvm_sha}

NEOVIM_VERSION=${neovim_tag}
NEOVIM_APPIMAGE_SHA256_x86_64=${neovim_sha_x86}
NEOVIM_APPIMAGE_SHA256_arm64=${neovim_sha_arm64}

LAZYGIT_VERSION=${lazygit_version}
LAZYGIT_TAR_SHA256_x86_64=${lazygit_sha_x86}
LAZYGIT_TAR_SHA256_arm64=${lazygit_sha_arm64}

JUST_VERSION=${just_version}
JUST_TAR_SHA256_x86_64=${just_sha_x86}
JUST_TAR_SHA256_arm64=${just_sha_arm64}

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

SUPERFILE_VERSION=${superfile_tag}
SUPERFILE_TAR_SHA256_amd64=${superfile_sha_amd64}
SUPERFILE_TAR_SHA256_arm64=${superfile_sha_arm64}

ATUIN_VERSION=${atuin_tag}
ATUIN_TAR_SHA256_x86_64_unknown_linux_gnu=${atuin_sha_x86}
ATUIN_TAR_SHA256_aarch64_unknown_linux_gnu=${atuin_sha_arm64}

HERDR_VERSION=${herdr_version}
HERDR_BINARY_SHA256_x86_64=${herdr_sha_x86}
HERDR_BINARY_SHA256_arm64=${herdr_sha_arm64}
HERDR_WINDOWS_PREVIEW_TAG=${herdr_windows_preview_tag}
HERDR_WINDOWS_ASSET=${herdr_windows_asset}
HERDR_WINDOWS_BINARY_SHA256_x86_64=${herdr_windows_sha}

ZOXIDE_INSTALLER_SHA256=${zoxide_sha}

RUSTUP_INSTALLER_SHA256=${rustup_sha}

UV_INSTALLER_SHA256=${uv_sha}

BUN_INSTALLER_SHA256=${bun_sha}

HOMEBREW_INSTALLER_SHA256=${homebrew_installer_sha}

AZURE_CLI_APT_INSTALLER_SHA256=${azure_cli_apt_installer_sha}

EZA_KEY_FINGERPRINT=${eza_key_fingerprint}

OHMYZSH_REF=${ohmyzsh_ref}
ZSH_AUTOSUGGESTIONS_REF=${zsh_autosuggestions_ref}
ZSH_SYNTAX_HIGHLIGHTING_REF=${zsh_syntax_highlighting_ref}
POWERLEVEL10K_REF=${powerlevel10k_ref}
POWERLEVEL10K_MEDIA_REF=${powerlevel10k_media_ref}

MESLO_REGULAR_TTF_SHA256=${meslo_regular_sha}
MESLO_BOLD_TTF_SHA256=${meslo_bold_sha}
MESLO_ITALIC_TTF_SHA256=${meslo_italic_sha}
MESLO_BOLD_ITALIC_TTF_SHA256=${meslo_bold_italic_sha}
EOF

{
    echo "# Auto-generated by scripts/bump-versions.sh"
    echo "# $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo
    echo "\$DotfilesVersions = [ordered]@{"
    while IFS='=' read -r name value; do
        [[ "$name" =~ ^[A-Za-z0-9_]+$ ]] || continue
        if [[ "$value" == *"'"* ]]; then
            echo "Cannot write PowerShell pin containing a single quote: $name" >&2
            exit 1
        fi
        printf "    %s = '%s'\n" "$name" "$value"
    done <"$generated_versions"
    echo '}'
    echo
    echo "return \$DotfilesVersions"
} >"$generated_powershell_versions"

mv "$generated_versions" "$VERSIONS_FILE"
mv "$generated_powershell_versions" "$POWERSHELL_VERSIONS_FILE"

echo "Updated $VERSIONS_FILE and $POWERSHELL_VERSIONS_FILE:"
cat "$VERSIONS_FILE"
