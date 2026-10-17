#!/bin/bash
# shellcheck disable=SC2034  # Sets variables for the scripts that source it.

# Pinned upstream release assets: the single source of truth for download URLs
# and pin names. Used by the installers (install_release), the pin updater
# (scripts/bump-versions.sh), and the pin checks.
#
# Every tool <name> is pinned in install/versions.env as:
#   <NAME>_VERSION              version without a leading "v"
#   <NAME>_SHA256_<arch>        per architecture (x86_64, arm64)
#   <NAME>_SHA256_any           for architecture-independent assets (tmux)

# Tools install/release-tools.sh installs on Linux (Homebrew on macOS, pacman on Arch).
RELEASE_TOOLS=(just lazygit fzf zoxide delta bat fd hyperfine glow fastfetch atuin yazi superfile)

# All pinned release assets; herdr, mise, neovim, and tmux have dedicated installers.
PINNED_RELEASES=("${RELEASE_TOOLS[@]}" herdr mise neovim tmux)

# Print the architectures a tool publishes separate assets for.
release_arches() {
    case "$1" in
        tmux) echo any ;;
        *) echo "x86_64 arm64" ;;
    esac
}

# Describe a tool's release asset for one architecture.
# Usage: release_info <tool> <arch> [version]   (version defaults to <NAME>_VERSION)
# Sets:
#   RELEASE_VERSION   pinned version
#   RELEASE_REPO      GitHub owner/repo
#   RELEASE_URL       asset download URL
#   RELEASE_ASSET     asset file name
#   RELEASE_KIND      tar | zip | bin | deb | appimage | source
#   RELEASE_BINS      binaries to install from the asset (tar, zip, bin)
#   RELEASE_COMMANDS  commands whose version may satisfy the pin
#   RELEASE_DEST      install directory for RELEASE_BINS
#   RELEASE_PACMAN    Arch Linux package name
#   RELEASE_SHA_VAR   name of the checksum pin
release_info() {
    local tool="$1" arch="$2" upper version_var v gnu deb tag
    upper="$(printf '%s' "$tool" | tr '[:lower:]' '[:upper:]')"
    version_var="${upper}_VERSION"
    v="${3:-${!version_var:-}}"
    v="${v#v}"

    case "$arch" in
        x86_64) gnu="x86_64" deb="amd64" ;;
        arm64) gnu="aarch64" deb="arm64" ;;
        *) gnu="" deb="" ;;
    esac

    RELEASE_VERSION="$v"
    RELEASE_SHA_VAR="${upper}_SHA256_${arch}"
    RELEASE_BINS="$tool"
    RELEASE_COMMANDS="$tool"
    RELEASE_DEST="/usr/local/bin"
    RELEASE_PACMAN="$tool"
    tag="v$v"

    case "$tool" in
        just)
            RELEASE_REPO="casey/just" tag="$v" RELEASE_KIND="tar"
            RELEASE_ASSET="just-$v-$gnu-unknown-linux-musl.tar.gz" ;;
        lazygit)
            RELEASE_REPO="jesseduffield/lazygit" RELEASE_KIND="tar"
            RELEASE_ASSET="lazygit_${v}_Linux_${arch}.tar.gz" ;;
        fzf)
            RELEASE_REPO="junegunn/fzf" RELEASE_KIND="tar"
            RELEASE_ASSET="fzf-$v-linux_$deb.tar.gz" ;;
        zoxide)
            RELEASE_REPO="ajeetdsouza/zoxide" RELEASE_KIND="tar" RELEASE_DEST="$HOME/.local/bin"
            RELEASE_ASSET="zoxide-$v-$gnu-unknown-linux-musl.tar.gz" ;;
        delta)
            RELEASE_REPO="dandavison/delta" tag="$v" RELEASE_KIND="deb" RELEASE_PACMAN="git-delta"
            RELEASE_ASSET="git-delta_${v}_$deb.deb" ;;
        bat | fd | hyperfine)
            # Ubuntu's own packages name bat and fd batcat and fdfind.
            RELEASE_REPO="sharkdp/$tool" RELEASE_KIND="deb"
            RELEASE_ASSET="${tool}_${v}_$deb.deb"
            case "$tool" in
                bat) RELEASE_COMMANDS="bat batcat" ;;
                fd) RELEASE_COMMANDS="fd fdfind" ;;
            esac ;;
        glow)
            RELEASE_REPO="charmbracelet/glow" RELEASE_KIND="deb"
            RELEASE_ASSET="glow_${v}_$deb.deb" ;;
        fastfetch)
            RELEASE_REPO="fastfetch-cli/fastfetch" tag="$v" RELEASE_KIND="deb"
            RELEASE_ASSET="fastfetch-linux-${deb/arm64/aarch64}.deb" ;;
        atuin)
            RELEASE_REPO="atuinsh/atuin" RELEASE_KIND="tar" RELEASE_DEST="$HOME/.local/bin"
            RELEASE_ASSET="atuin-$gnu-unknown-linux-musl.tar.gz" ;;
        yazi)
            RELEASE_REPO="sxyazi/yazi" RELEASE_KIND="zip" RELEASE_DEST="$HOME/.local/bin" RELEASE_BINS="yazi ya"
            RELEASE_ASSET="yazi-$gnu-unknown-linux-musl.zip" ;;
        superfile)
            RELEASE_REPO="yorukot/superfile" RELEASE_KIND="tar" RELEASE_DEST="$HOME/.local/bin"
            RELEASE_BINS="spf" RELEASE_COMMANDS="spf"
            RELEASE_ASSET="superfile-linux-v$v-$deb.tar.gz" ;;
        herdr)
            RELEASE_REPO="herdrdev/herdr" RELEASE_KIND="bin" RELEASE_DEST="$HOME/.local/bin"
            RELEASE_ASSET="herdr-linux-$gnu" ;;
        mise)
            RELEASE_REPO="jdx/mise" RELEASE_KIND="bin" RELEASE_DEST="$HOME/.local/bin"
            RELEASE_ASSET="mise-v$v-linux-${deb/amd64/x64}" ;;
        neovim)
            RELEASE_REPO="neovim/neovim" RELEASE_KIND="appimage" RELEASE_COMMANDS="nvim"
            RELEASE_ASSET="nvim-linux-$arch.appimage" ;;
        tmux)
            RELEASE_REPO="tmux/tmux" tag="$v" RELEASE_KIND="source"
            RELEASE_ASSET="tmux-$v.tar.gz" ;;
        *)
            echo "Unknown pinned release: $tool" >&2
            return 1 ;;
    esac

    RELEASE_URL="https://github.com/$RELEASE_REPO/releases/download/$tag/$RELEASE_ASSET"
}
