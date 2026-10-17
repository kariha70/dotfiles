#!/bin/bash

# Shared helper functions for installer scripts.

# shellcheck source=releases.sh
source "$(dirname "${BASH_SOURCE[0]}")/releases.sh"

is_true() {
    case "${1:-}" in
        1|true|TRUE|yes|YES|y|Y|on|ON) return 0 ;;
        *) return 1 ;;
    esac
}

# --- APT helpers -----------------------------------------------------------

: "${APT_UPDATE_SENTINEL:=/tmp/dotfiles_apt_updated_$$}"
export APT_UPDATE_SENTINEL

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
    if command -v dpkg-query >/dev/null 2>&1; then
        apt_load_installed_cache || return 1
        grep -Fxq "$pkg" <<<"$APT_INSTALLED_CACHE"
        return
    fi
    if command -v pacman >/dev/null 2>&1; then
        pacman -Qq "$pkg" >/dev/null 2>&1
        return
    fi
    return 1
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

# --- Pacman helpers --------------------------------------------------------

: "${PACMAN_UPDATE_SENTINEL:=/tmp/dotfiles_pacman_updated_$$}"
export PACMAN_UPDATE_SENTINEL

# Arch Linux does not support partial upgrades, so the first package install
# in a bootstrap run performs a full system upgrade.
pacman_update_once() {
    if ! command -v pacman >/dev/null 2>&1; then
        return 1
    fi
    if [ -n "${PACMAN_UPDATED:-}" ] || [ -f "${PACMAN_UPDATE_SENTINEL:-/tmp/dotfiles_pacman_updated}" ]; then
        echo "Skipping pacman system update (already run)."
        return 0
    fi
    echo "Updating Arch Linux packages..."
    sudo pacman -Syu --noconfirm
    export PACMAN_UPDATED=1
    touch "${PACMAN_UPDATE_SENTINEL:-/tmp/dotfiles_pacman_updated}"
}

pacman_package_available() {
    local pkg="$1"
    command -v pacman >/dev/null 2>&1 && pacman -Si "$pkg" >/dev/null 2>&1
}

pacman_install() {
    if [ "$#" -eq 0 ]; then
        return 0
    fi
    pacman_update_once
    sudo pacman -S --needed --noconfirm "$@"
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

normalize_version() {
    printf '%s\n' "${1%%-*}"
}

version_at_least() {
    local have="$1" need="$2"
    [ "$(printf '%s\n%s\n' "$need" "$have" | sort -V | head -n 1)" = "$need" ]
}

# Print the first dotted version number a command reports via `--version`
# (`go version` for Go, `tmux -V` for tmux).
# Usage: command_version <command-or-path>
command_version() {
    local cmd="$1" version_arg="--version" output version
    command -v "$cmd" >/dev/null 2>&1 || return 1
    case "$(basename "$cmd")" in
        go) version_arg="version" ;;
        tmux) version_arg="-V" ;;
    esac
    output="$("$cmd" "$version_arg" 2>/dev/null || true)"
    # An optional letter suffix keeps releases like tmux 3.6a comparable.
    version="$(awk '!found && match($0, /[0-9]+\.[0-9]+(\.[0-9]+)?[a-z]?/) { print substr($0, RSTART, RLENGTH); found = 1 }' <<<"$output")"
    [ -n "$version" ] || return 1
    printf '%s\n' "$version"
}

# Return 0 when any candidate command/path reports a version at or above the
# pinned version. Bumping a pin therefore upgrades existing installs on the next
# run, while newer user-managed installs are never downgraded.
# Usage: pinned_version_satisfied <pinned-version> <command-or-path>...
pinned_version_satisfied() {
    local pinned candidate installed
    pinned="$(normalize_version "${1#v}")"
    shift
    if [ -z "$pinned" ]; then
        echo "Missing pinned version for $(basename "${1:-tool}"). Run scripts/bump-versions.sh." >&2
        return 1
    fi
    for candidate in "$@"; do
        installed="$(command_version "$candidate")" || continue
        if version_at_least "$installed" "$pinned"; then
            echo "$(basename "$candidate") ${installed} satisfies pinned version ${pinned}."
            return 0
        fi
        echo "$(basename "$candidate") ${installed} is older than pinned version ${pinned}."
    done
    return 1
}

# Download a pinned upstream .deb, verify it, and install it with apt so its
# dependencies and package conflicts are resolved.
# Usage: install_verified_deb <url> <expected_sha> <label>
install_verified_deb() {
    local url="$1" expected_sha="$2" label="$3" tmp_dir status=0
    tmp_dir="$(mktemp -d)"
    if download_and_verify "$url" "$tmp_dir/package.deb" "$expected_sha" "$label"; then
        apt_update_once
        sudo apt-get install -y --no-install-recommends "$tmp_dir/package.deb" || status=$?
    else
        status=1
    fi
    rm -rf "$tmp_dir"
    return "$status"
}

# Print the mise binary: the pinned ~/.local/bin install (Linux) first, so an
# older mise earlier on PATH is not used, then PATH, then Homebrew, whose
# shellenv may not be loaded yet during a fresh macOS bootstrap.
resolve_mise_bin() {
    local candidate
    if [ -x "$HOME/.local/bin/mise" ]; then
        printf '%s\n' "$HOME/.local/bin/mise"
        return 0
    fi
    if command -v mise >/dev/null 2>&1; then
        command -v mise
        return 0
    fi
    for candidate in /opt/homebrew/bin/mise /usr/local/bin/mise; do
        if [ -x "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

# Declare npm CLIs as mise tools in a generated conf.d file and install them.
# mise installs each package in its own directory, independent of the active
# Node.js version, so changing NODE_VERSION or setting up another machine no
# longer means rerunning `npm install -g`.
# Entries are read from stdin, one per line: `<package> [allow-builds]`.
# `allow-builds` lets the package's own install scripts run (mise skips them
# by default). Blank lines and `#` comments are ignored.
# Usage: mise_install_npm_tools <conf-name> < entries
mise_install_npm_tools() {
    local conf_name="$1" conf_dir="$HOME/.config/mise/conf.d" mise_bin tmp pkg flag
    mise_bin="$(resolve_mise_bin)" || {
        echo "mise not found. Run install/mise.sh first." >&2
        return 1
    }
    tmp="$(mktemp)"
    {
        echo "# Generated by the dotfiles bootstrap; edit the source list in the dotfiles repo."
        echo "[tools]"
        while read -r pkg flag _; do
            case "$pkg" in
                ""|\#*) continue ;;
            esac
            if [ "${flag:-}" = "allow-builds" ]; then
                printf '"npm:%s" = { version = "latest", allow_builds = ["%s"] }\n' "$pkg" "$pkg"
            else
                printf '"npm:%s" = "latest"\n' "$pkg"
            fi
        done
    } >"$tmp"
    mkdir -p "$conf_dir"
    if cmp -s "$tmp" "$conf_dir/$conf_name.toml"; then
        rm -f "$tmp"
    else
        mv "$tmp" "$conf_dir/$conf_name.toml"
    fi
    # Run from $HOME so a project's mise.toml in the caller's directory neither
    # changes the result nor triggers a trust prompt.
    (cd "$HOME" && MISE_YES=1 "$mise_bin" install)
}

# Install the pinned release of a tool from install/lib/releases.sh unless a
# candidate command already reports the pinned version or newer.
# Usage: install_release <tool>
install_release() {
    local tool="$1" arch tmp_dir sha bin found sudo_cmd="" status=0
    local -a candidates=()
    arch="$(get_arch)" || return 1
    release_info "$tool" "$arch" || return 1
    if [ -z "$RELEASE_VERSION" ]; then
        echo "Pinned version for $tool is missing. Run scripts/bump-versions.sh." >&2
        return 1
    fi

    read -r -a candidates <<<"$RELEASE_COMMANDS"
    if [ "$RELEASE_KIND" != "deb" ]; then
        candidates+=("$RELEASE_DEST/${RELEASE_BINS%% *}")
    fi
    if pinned_version_satisfied "$RELEASE_VERSION" "${candidates[@]}"; then
        return 0
    fi

    echo "Installing $tool $RELEASE_VERSION..."
    sha="${!RELEASE_SHA_VAR:-}"
    if [ "$RELEASE_KIND" = "deb" ]; then
        install_verified_deb "$RELEASE_URL" "$sha" "$tool ($arch)"
        return
    fi

    tmp_dir="$(mktemp -d)"
    mkdir -p "$tmp_dir/files"
    if ! download_and_verify "$RELEASE_URL" "$tmp_dir/$RELEASE_ASSET" "$sha" "$tool ($arch)"; then
        rm -rf "$tmp_dir"
        return 1
    fi
    if [ "$RELEASE_KIND" = "zip" ] && ! command -v unzip >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
        apt_update_once
        sudo apt-get install -y --no-install-recommends unzip
    fi
    case "$RELEASE_KIND" in
        tar) tar -xf "$tmp_dir/$RELEASE_ASSET" -C "$tmp_dir/files" ;;
        zip) unzip -q "$tmp_dir/$RELEASE_ASSET" -d "$tmp_dir/files" ;;
        bin) mv "$tmp_dir/$RELEASE_ASSET" "$tmp_dir/files/$RELEASE_BINS" ;;
        *)
            echo "install_release does not handle $RELEASE_KIND assets ($tool)." >&2
            rm -rf "$tmp_dir"
            return 1 ;;
    esac

    if [ "$RELEASE_DEST" = "/usr/local/bin" ]; then
        sudo_cmd="sudo"
    else
        mkdir -p "$RELEASE_DEST"
    fi
    for bin in $RELEASE_BINS; do
        found="$(find "$tmp_dir/files" -type f -name "$bin" | head -n 1)"
        if [ -z "$found" ]; then
            echo "$bin not found in the $tool release asset." >&2
            status=1
            break
        fi
        $sudo_cmd install -m 0755 "$found" "$RELEASE_DEST/$bin"
    done
    rm -rf "$tmp_dir"
    [ "$status" -eq 0 ] || return "$status"

    # Catch binaries that cannot run here, e.g. builds needing a newer glibc.
    if ! pinned_version_satisfied "$RELEASE_VERSION" "$RELEASE_DEST/${RELEASE_BINS%% *}" >/dev/null; then
        echo "$tool $RELEASE_VERSION was installed to $RELEASE_DEST but does not run on this system." >&2
        return 1
    fi
    echo "$tool $RELEASE_VERSION installed to $RELEASE_DEST."
}

# Load Homebrew's environment when brew is installed but not yet on PATH.
load_brew_shellenv() {
    local brew_bin
    command -v brew >/dev/null 2>&1 && return 0
    for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$brew_bin" ]; then
            eval "$("$brew_bin" shellenv)"
            return 0
        fi
    done
    return 1
}

# Download an armored apt signing key, require that it holds exactly the
# expected primary key, and write it dearmored for `signed-by=`.
# Usage: fetch_apt_key <url> <expected-fingerprint> <output.gpg>
fetch_apt_key() {
    local url="$1" expected_fp="$2" output="$3" armored actual_fps
    armored="$(mktemp)"
    if ! curl -fLsS "$url" -o "$armored"; then
        rm -f "$armored"
        return 1
    fi
    actual_fps="$(gpg --batch --with-colons --import-options show-only --import "$armored" 2>/dev/null |
        awk -F: '/^pub:/ { want = 1; next } want && /^fpr:/ { print $10; want = 0 }')"
    if [ -z "$expected_fp" ] || [ "$actual_fps" != "$expected_fp" ]; then
        echo "Fingerprint mismatch for apt signing key from $url." >&2
        echo "Expected: ${expected_fp:-<missing pin>}" >&2
        echo "Actual:   ${actual_fps:-<none>}" >&2
        rm -f "$armored"
        return 1
    fi
    gpg --batch --yes --dearmor -o "$output" "$armored"
    rm -f "$armored"
}

# Install an apt keyring and source list when they differ from the desired
# state. Sets APT_SOURCE_CHANGED=1 when anything was written.
# Usage: install_apt_source <verified_keyring> <keyring_dest> <list_file> <source_line>
install_apt_source() {
    local keyring_src="$1" keyring_dest="$2" list_file="$3" source_line="$4"
    APT_SOURCE_CHANGED=0
    if [ ! -f "$keyring_dest" ] || ! cmp -s "$keyring_src" "$keyring_dest"; then
        sudo install -d -m 755 "$(dirname "$keyring_dest")"
        sudo install -m 644 "$keyring_src" "$keyring_dest"
        APT_SOURCE_CHANGED=1
    fi
    if [ ! -f "$list_file" ] || [ "$(cat "$list_file")" != "$source_line" ]; then
        printf '%s\n' "$source_line" | sudo tee "$list_file" >/dev/null
        sudo chmod 644 "$list_file"
        APT_SOURCE_CHANGED=1
    fi
    export APT_SOURCE_CHANGED
}

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
