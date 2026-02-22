#!/bin/bash

# Shared helper functions for installer scripts.

: "${APT_UPDATE_SENTINEL:=/tmp/dotfiles_apt_updated_$$}"
export APT_UPDATE_SENTINEL

# Return 0 when running inside WSL.
is_wsl() {
    grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null
}

# Return 0 when running on macOS.
is_macos() {
    [ "$(uname -s)" = "Darwin" ]
}

# Return 0 when running on Linux.
is_linux() {
    [ "$(uname -s)" = "Linux" ]
}

# Clean up deprecated/broken third-party apt sources to prevent update failures.
remove_deprecated_apt_sources() {
    local charm_list="/etc/apt/sources.list.d/charm.list"
    if [ -f "$charm_list" ] && grep -q "repo.charm.sh/apt" "$charm_list"; then
        echo "Removing deprecated Charm apt source (no longer used for Glow)."
        sudo rm -f "$charm_list"
    fi
}

# Run apt-get update only once per script invocation.
apt_update_once() {
    if ! command -v apt-get >/dev/null; then
        return 1
    fi
    if [ "${1:-}" = "--force" ]; then
        shift
    elif [ -n "${APT_UPDATED:-}" ] || [ -f "${APT_UPDATE_SENTINEL:-/tmp/dotfiles_apt_updated}" ]; then
        echo "Skipping apt-get update (already run)."
        return 0
    fi
    echo "Updating apt package index..."
    remove_deprecated_apt_sources
    sudo apt-get update
    export APT_UPDATED=1
    touch "${APT_UPDATE_SENTINEL:-/tmp/dotfiles_apt_updated}"
}

# Ensure ~/.local/bin exists.
ensure_local_bin() {
    mkdir -p "$HOME/.local/bin"
}

# Normalize uname arch to stable tokens used by installers.
get_arch() {
    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64|amd64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            echo "Unsupported architecture: $arch" >&2
            return 1
            ;;
    esac
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
