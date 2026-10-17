#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSIONS_FILE="${VERSIONS_FILE:-$ROOT_DIR/install/versions.env}"
POWERSHELL_VERSIONS_FILE="${POWERSHELL_VERSIONS_FILE:-$ROOT_DIR/install/versions.ps1}"
TMP_DIR="$(mktemp -d)"
# shellcheck source=../install/lib/releases.sh
source "$ROOT_DIR/install/lib/releases.sh"
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

generated_versions="$TMP_DIR/versions.env"
generated_powershell_versions="$TMP_DIR/versions.ps1"
{
    echo "# Auto-generated by scripts/bump-versions.sh"
    echo "# $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
} >"$generated_versions"

# Append a blank-line separated group of NAME=value pins.
emit() {
    {
        echo
        printf '%s\n' "$@"
    } >>"$generated_versions"
}

# Pinned release assets (install/lib/releases.sh). Override a version with
# <NAME>_VERSION_OVERRIDE, e.g. NEOVIM_VERSION_OVERRIDE=0.12.5.
for tool in "${PINNED_RELEASES[@]}"; do
    upper="$(printf '%s' "$tool" | tr '[:lower:]' '[:upper:]')"
    override_var="${upper}_VERSION_OVERRIDE"
    current_var="${upper}_VERSION"
    version="${!override_var:-}"

    if [ -z "$version" ]; then
        release_info "$tool" x86_64 "@VERSION@"
        repo="$RELEASE_REPO"
        if [[ "$RELEASE_ASSET" == *"@VERSION@"* ]]; then
            version="$(latest_tag "$repo")" || true
        else
            # Asset names without a version can be missing from the newest
            # release, so pick the newest release that has all of them.
            assets=()
            for arch in $(release_arches "$tool"); do
                release_info "$tool" "$arch" "@VERSION@"
                assets+=("$RELEASE_ASSET")
            done
            current_tag=""
            if [ -n "${!current_var:-}" ]; then
                release_info "$tool" x86_64
                current_tag="$(basename "$(dirname "$RELEASE_URL")")"
            fi
            version="$(latest_release_with_assets "$repo" "$current_tag" "${assets[@]}")" || true
        fi
    fi
    version="${version#v}"
    if [ -z "$version" ] || [ "$version" = "null" ]; then
        echo "Could not determine the latest $tool release."
        exit 1
    fi

    pins=("${upper}_VERSION=${version}")
    for arch in $(release_arches "$tool"); do
        release_info "$tool" "$arch" "$version"
        sha="$(fetch_sha "$RELEASE_URL" "$TMP_DIR/$RELEASE_ASSET")"
        pins+=("${RELEASE_SHA_VAR}=${sha}")
    done
    emit "${pins[@]}"
done

# Herdr Windows preview build (published separately from the Linux releases).
herdr_preview_manifest="$TMP_DIR/herdr-preview.json"
curl "${CURL_ARGS[@]}" "https://herdr.dev/preview.json" -o "$herdr_preview_manifest"
herdr_windows_url=$(jq -er '.assets["windows-x86_64"].url' "$herdr_preview_manifest")
herdr_windows_declared_sha=$(jq -er '.assets["windows-x86_64"].sha256' "$herdr_preview_manifest")
herdr_windows_preview_tag=$(basename "$(dirname "$herdr_windows_url")")
herdr_windows_asset=$(basename "$herdr_windows_url")
case "$herdr_windows_url" in
    "https://github.com/herdrdev/herdr/releases/download/${herdr_windows_preview_tag}/herdr-windows-x86_64.exe" | \
        "https://github.com/herdrdev/herdr/releases/download/${herdr_windows_preview_tag}/herdr-windows-x86_64.zip") ;;
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
emit "HERDR_WINDOWS_PREVIEW_TAG=${herdr_windows_preview_tag}" \
    "HERDR_WINDOWS_ASSET=${herdr_windows_asset}" \
    "HERDR_WINDOWS_BINARY_SHA256_x86_64=${herdr_windows_sha}"

# Language runtimes installed and checksum-verified by mise.
node_version="${NODE_VERSION_OVERRIDE:-$(curl "${CURL_ARGS[@]}" "https://nodejs.org/dist/index.json" | jq -er '[ .[] | select(.lts != false) | .version ][0]')}"
go_version="${GO_VERSION_OVERRIDE:-$(curl "${CURL_ARGS[@]}" "https://go.dev/dl/?mode=json" | jq -er '[ .[] | select(.stable) | .version ][0]')}"
node_version="${node_version#v}"
go_version="${go_version#go}"
if [ -z "$node_version" ] || [ -z "$go_version" ]; then
    echo "Could not determine the latest Node.js LTS or Go release."
    exit 1
fi
emit "NODE_VERSION=${node_version}" "GO_VERSION=${go_version}"

# Installer scripts and apt keyrings pinned by SHA256.
for pin in \
    "RUSTUP_INSTALLER_SHA256|https://sh.rustup.rs" \
    "UV_INSTALLER_SHA256|https://astral.sh/uv/install.sh" \
    "BUN_INSTALLER_SHA256|https://bun.sh/install" \
    "HOMEBREW_INSTALLER_SHA256|https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" \
    "AZURE_CLI_APT_INSTALLER_SHA256|https://aka.ms/InstallAzureCLIDeb" \
    "GH_APT_KEYRING_SHA256|https://cli.github.com/packages/githubcli-archive-keyring.gpg"; do
    name="${pin%%|*}"
    emit "${name}=$(fetch_sha "${pin#*|}" "$TMP_DIR/$name")"
done

# apt repository signing keys pinned by fingerprint.
curl "${CURL_ARGS[@]}" "https://raw.githubusercontent.com/eza-community/eza/main/deb.asc" -o "$TMP_DIR/eza.asc"
emit "EZA_KEY_FINGERPRINT=$(gpg_fingerprint "$TMP_DIR/eza.asc")"

# The git-core PPA key is cross-checked between Launchpad and the keyserver.
git_core_ppa_fingerprint="$(curl "${CURL_ARGS[@]}" "https://api.launchpad.net/1.0/~git-core/+archive/ubuntu/ppa" | jq -er '.signing_key_fingerprint')"
curl "${CURL_ARGS[@]}" "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x${git_core_ppa_fingerprint}" -o "$TMP_DIR/git-core.asc"
if [ "$(gpg_fingerprint "$TMP_DIR/git-core.asc")" != "$git_core_ppa_fingerprint" ]; then
    echo "git-core PPA signing key fingerprint does not match Launchpad metadata."
    exit 1
fi
emit "GIT_CORE_PPA_KEY_FINGERPRINT=${git_core_ppa_fingerprint}"

# Pinned git refs (override with <NAME>_OVERRIDE).
refs=()
for pin in \
    "OHMYZSH_REF|ohmyzsh/ohmyzsh" \
    "ZSH_AUTOSUGGESTIONS_REF|zsh-users/zsh-autosuggestions" \
    "ZSH_SYNTAX_HIGHLIGHTING_REF|zsh-users/zsh-syntax-highlighting" \
    "POWERLEVEL10K_REF|romkatv/powerlevel10k" \
    "POWERLEVEL10K_MEDIA_REF|romkatv/powerlevel10k-media"; do
    name="${pin%%|*}"
    override_var="${name}_OVERRIDE"
    ref="${!override_var:-$(resolve_git_ref "$name" "${pin#*|}" "${!name:-}")}"
    printf -v "$name" '%s' "$ref"
    refs+=("${name}=${ref}")
done
emit "${refs[@]}"

# MesloLGS NF fonts from the pinned powerlevel10k-media commit.
fonts=()
for font in "REGULAR|Regular" "BOLD|Bold" "ITALIC|Italic" "BOLD_ITALIC|Bold%20Italic"; do
    fonts+=("MESLO_${font%%|*}_TTF_SHA256=$(fetch_sha "https://raw.githubusercontent.com/romkatv/powerlevel10k-media/${POWERLEVEL10K_MEDIA_REF}/MesloLGS%20NF%20${font#*|}.ttf" "$TMP_DIR/meslo-${font%%|*}.ttf")")
done
emit "${fonts[@]}"

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
