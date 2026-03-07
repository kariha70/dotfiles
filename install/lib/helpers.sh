#!/bin/bash

# Shared helper functions for installer scripts.

# --- Logging ---------------------------------------------------------------

log_info()  { echo "$*"; }
log_warn()  { echo "WARNING: $*" >&2; }

is_true() {
    case "${1:-}" in
        1|true|TRUE|yes|YES|y|Y|on|ON) return 0 ;;
        *) return 1 ;;
    esac
}

# --- APT helpers -----------------------------------------------------------

: "${APT_UPDATE_SENTINEL:=/tmp/dotfiles_apt_updated_$$}"
export APT_UPDATE_SENTINEL

# Clean up deprecated/broken third-party apt sources to prevent update failures.
remove_deprecated_apt_sources() {
    local charm_list="/etc/apt/sources.list.d/charm.list"
    if [ -f "$charm_list" ] && grep -q "repo.charm.sh/apt" "$charm_list"; then
        echo "Removing deprecated Charm apt source (no longer used for Glow)."
        sudo rm -f "$charm_list"
    fi
}

# Run apt-get update only once per script invocation.
apt_update_impl() {
    local force="${1:-0}"
    if ! command -v apt-get >/dev/null; then
        return 1
    fi
    if [ "$force" != "1" ] && { [ -n "${APT_UPDATED:-}" ] || [ -f "${APT_UPDATE_SENTINEL:-/tmp/dotfiles_apt_updated}" ]; }; then
        echo "Skipping apt-get update (already run)."
        return 0
    fi
    echo "Updating apt package index..."
    remove_deprecated_apt_sources
    sudo apt-get update
    export APT_UPDATED=1
    touch "${APT_UPDATE_SENTINEL:-/tmp/dotfiles_apt_updated}"
}

apt_update_once() {
    apt_update_impl 0
}

apt_update_force() {
    apt_update_impl 1
}

# --- Platform detection ----------------------------------------------------

# Cache uname once per shell process.
platform_uname() {
    if [ -z "${DOTFILES_UNAME_S:-}" ]; then
        DOTFILES_UNAME_S="$(uname -s)"
        export DOTFILES_UNAME_S
    fi
    printf '%s\n' "$DOTFILES_UNAME_S"
}

# Return 0 when running inside WSL.
is_wsl() {
    if [ -z "${DOTFILES_IS_WSL:-}" ]; then
        if grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; then
            DOTFILES_IS_WSL=1
        else
            DOTFILES_IS_WSL=0
        fi
        export DOTFILES_IS_WSL
    fi
    [ "$DOTFILES_IS_WSL" = "1" ]
}

# Return 0 when running on macOS.
is_macos() {
    [ "$(platform_uname)" = "Darwin" ]
}

# Return 0 when running on Linux.
is_linux() {
    [ "$(platform_uname)" = "Linux" ]
}

# Ensure ~/.local/bin exists.
ensure_local_bin() {
    mkdir -p "$HOME/.local/bin"
}

# Normalize uname arch to stable tokens used by installers.
get_arch() {
    local arch
    if [ -n "${DOTFILES_ARCH:-}" ]; then
        printf '%s\n' "$DOTFILES_ARCH"
        return 0
    fi
    arch="$(uname -m)"
    case "$arch" in
        x86_64|amd64)
            DOTFILES_ARCH="x86_64"
            ;;
        aarch64|arm64)
            DOTFILES_ARCH="arm64"
            ;;
        *)
            echo "Unsupported architecture: $arch" >&2
            return 1
            ;;
    esac
    export DOTFILES_ARCH
    printf '%s\n' "$DOTFILES_ARCH"
}

# Append a value to an array only once.
append_unique() {
    local array_name="$1"
    # shellcheck disable=SC2034
    local value="$2"
    # shellcheck disable=SC2034
    local current
    eval "for current in \"\${${array_name}[@]}\"; do
        if [ \"\$current\" = \"\$value\" ]; then
            return 0
        fi
    done
    ${array_name}+=(\"\$value\")"
}

# Cache the installed package set to avoid one dpkg process per package.
apt_load_installed_cache() {
    if [ "${APT_INSTALLED_CACHE_LOADED:-0}" = "1" ]; then
        return 0
    fi
    if ! command -v dpkg-query >/dev/null 2>&1; then
        return 1
    fi
    APT_INSTALLED_CACHE="$(dpkg-query -W -f='${binary:Package}\n' 2>/dev/null || true)"
    APT_INSTALLED_CACHE_LOADED=1
}

package_is_installed() {
    local pkg="$1"
    apt_load_installed_cache || return 1
    grep -Fxq "$pkg" <<<"$APT_INSTALLED_CACHE"
}

# Cache the package index names once per shell process.
apt_load_available_cache() {
    if [ "${APT_AVAILABLE_CACHE_LOADED:-0}" = "1" ]; then
        return 0
    fi
    if ! command -v apt-cache >/dev/null 2>&1; then
        return 1
    fi
    APT_AVAILABLE_CACHE="$(apt-cache pkgnames 2>/dev/null || true)"
    APT_AVAILABLE_CACHE_LOADED=1
}

apt_package_available() {
    local pkg="$1"
    apt_load_available_cache || return 1
    grep -Fxq "$pkg" <<<"$APT_AVAILABLE_CACHE"
}

filter_missing_packages() {
    local pkg
    for pkg in "$@"; do
        if package_is_installed "$pkg"; then
            continue
        fi
        printf '%s\n' "$pkg"
    done
}

# Print a file's SHA256 digest in a cross-platform way.
sha256_file() {
    local file="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file" | awk '{print $1}'
        return 0
    fi
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file" | awk '{print $1}'
        return 0
    fi
    echo "No SHA256 tool found (need sha256sum or shasum)." >&2
    return 1
}

# Verify a file against an expected sha256 checksum.
verify_sha256() {
    local file="$1" expected="$2" label="${3:-$1}"
    local actual
    actual=$(sha256_file "$file")
    if [ -z "$expected" ]; then
        echo "Missing checksum for $label. Run scripts/bump-versions.sh to refresh install/versions.env." >&2
        return 1
    fi
    if [ "$actual" != "$expected" ]; then
        echo "Checksum mismatch for $label" >&2
        echo "Expected: $expected" >&2
        echo "Actual:   $actual" >&2
        echo "Run scripts/bump-versions.sh if a new release is available." >&2
        return 1
    fi
}

# --- Version / download helpers --------------------------------------------

# Source install/versions.env relative to the calling script's directory.
# Usage: source_versions "$SCRIPT_DIR"
source_versions() {
    local script_dir="$1"
    local versions_file="${VERSIONS_FILE:-$script_dir/versions.env}"
    if [ -f "$versions_file" ]; then
        # shellcheck source=/dev/null
        source "$versions_file"
    else
        echo "versions.env not found at $versions_file. Run scripts/bump-versions.sh to generate it." >&2
        exit 1
    fi
}

# Download a file and verify its SHA256 checksum.
# Usage: download_and_verify <url> <output_path> <expected_sha> <label>
download_and_verify() {
    local url="$1" output="$2" expected_sha="$3" label="$4"
    curl -fLsS "$url" -o "$output"
    verify_sha256 "$output" "$expected_sha" "$label"
}
