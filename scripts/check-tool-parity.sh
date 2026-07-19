#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LINUX_PACKAGES=("$ROOT_DIR"/install/*.sh)
MACOS_PACKAGES="$ROOT_DIR/install/Brewfile"
WINDOWS_PACKAGES=("$ROOT_DIR"/install/*.ps1)

fail() {
    echo "Tool parity validation failed: $*" >&2
    exit 1
}

contains() {
    local needle="$1"
    shift
    grep -Fq -- "$needle" "$@"
}

# command|Linux declaration|Homebrew declaration|WinGet package ID
tool_declarations=(
    'age|add_optional_package age age|brew "age"|FiloSottile.age'
    'atuin|ATUIN_VERSION|brew "atuin"|Atuinsh.Atuin'
    'bat|        bat|brew "bat"|sharkdp.bat'
    'btop|        btop|brew "btop"|aristocratos.btop4win'
    'btm|add_optional_package bottom bottom|brew "bottom"|Clement.bottom'
    'delta|DELTA_VERSION|brew "git-delta"|dandavison.delta'
    'direnv|add_optional_package direnv direnv|brew "direnv"|direnv.direnv'
    'dust|add_first_available "dust" du-dust dust|brew "dust"|bootandy.dust'
    'duf|add_optional_package duf duf|brew "duf"|muesli.duf'
    'eza|EZA_KEY_FINGERPRINT|brew "eza"|eza-community.eza'
    'fastfetch|FASTFETCH_VERSION|brew "fastfetch"|Fastfetch-cli.Fastfetch'
    'fd|        fd-find|brew "fd"|sharkdp.fd'
    'fzf|        fzf|brew "fzf"|junegunn.fzf'
    'gh|add_optional_package gh "GitHub CLI (gh)"|brew "gh"|GitHub.cli'
    'glow|GLOW_VERSION|brew "glow"|charmbracelet.glow'
    'gping|add_optional_package gping gping|brew "gping"|orf.gping'
    'helm|add_optional_package helm helm|brew "helm"|Helm.Helm'
    'http|add_optional_package httpie "HTTPie"|brew "httpie"|HTTPie.HTTPie'
    'hyperfine|add_optional_package hyperfine hyperfine|brew "hyperfine"|sharkdp.hyperfine'
    'jq|        jq|brew "jq"|jqlang.jq'
    'just|add_optional_package just just|brew "just"|Casey.Just'
    'kubectl|add_optional_package kubectl kubectl|brew "kubectl"|Kubernetes.kubectl'
    'lazygit|LAZYGIT_VERSION|brew "lazygit"|JesseDuffield.lazygit'
    'mlr|add_optional_package miller "Miller (mlr)"|brew "miller"|Miller.Miller'
    'nvim|NEOVIM_VERSION|brew "neovim"|Neovim.Neovim'
    'procs|PROCS_APT_AVAILABLE|brew "procs"|dalance.procs'
    'rg|        ripgrep|brew "ripgrep"|BurntSushi.ripgrep.MSVC'
    'shellcheck|        shellcheck|brew "shellcheck"|koalaman.shellcheck'
    'tldr|add_optional_package tealdeer "tealdeer (tldr)"|brew "tealdeer"|dbrgn.tealdeer'
    'xh|add_optional_package xh xh|brew "xh"|ducaale.xh'
    'yazi|YAZI_VERSION|brew "yazi"|sxyazi.yazi'
    'zoxide|ZOXIDE_INSTALLER_SHA256|brew "zoxide"|ajeetdsouza.zoxide'
)

for declaration in "${tool_declarations[@]}"; do
    IFS='|' read -r command linux_token macos_token windows_token <<< "$declaration"
    contains "$linux_token" "${LINUX_PACKAGES[@]}" || fail "$command is missing from Linux packages"
    contains "$macos_token" "$MACOS_PACKAGES" || fail "$command is missing from the Brewfile"
    contains "$windows_token" "${WINDOWS_PACKAGES[@]}" || fail "$command is missing from Windows packages"
done

echo "Cross-platform CLI declarations are synchronized."
