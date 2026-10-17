#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LINUX_FILES=("$ROOT_DIR"/install/*.sh)
MACOS_FILES=("$ROOT_DIR/install/Brewfile" "$ROOT_DIR/install/ai-tools.sh" "$ROOT_DIR/install/mise.sh")
WINDOWS_FILES=("$ROOT_DIR"/install/*.ps1)
# shellcheck source=../install/lib/releases.sh
source "$ROOT_DIR/install/lib/releases.sh"

fail() {
    echo "Tool parity validation failed: $*" >&2
    exit 1
}

contains() {
    local needle="$1"
    shift
    grep -Fq -- "$needle" "$@"
}

# Linux declarations:
#   release:<tool>  pinned release in install/lib/releases.sh
#   package:<pkg>   package listed in install/packages.sh
#   <text>          literal text in an install/*.sh script
linux_declared() {
    case "$1" in
        release:*)
            case " ${PINNED_RELEASES[*]} " in
                *" ${1#release:} "*) return 0 ;;
            esac
            return 1 ;;
        package:*)
            grep -Eq "(^|[[:space:](])${1#package:}([[:space:])]|$)" "$ROOT_DIR/install/packages.sh" ;;
        *)
            contains "$1" "${LINUX_FILES[@]}" ;;
    esac
}

# command|Linux|Homebrew|Windows
tool_declarations=(
    'age|package:age|brew "age"|FiloSottile.age'
    'atuin|release:atuin|brew "atuin"|Atuinsh.Atuin'
    'bat|release:bat|brew "bat"|sharkdp.bat'
    'btop|package:btop|brew "btop"|aristocratos.btop4win'
    'btm|package:bottom|brew "bottom"|Clement.bottom'
    'delta|release:delta|brew "git-delta"|dandavison.delta'
    'direnv|package:direnv|brew "direnv"|direnv.direnv'
    'dust|package:dust|brew "dust"|bootandy.dust'
    'duf|package:duf|brew "duf"|muesli.duf'
    'eza|EZA_KEY_FINGERPRINT|brew "eza"|eza-community.eza'
    'fastfetch|release:fastfetch|brew "fastfetch"|Fastfetch-cli.Fastfetch'
    'fd|release:fd|brew "fd"|sharkdp.fd'
    'fzf|release:fzf|brew "fzf"|junegunn.fzf'
    'gh|GH_APT_KEYRING_SHA256|brew "gh"|GitHub.cli'
    'glow|release:glow|brew "glow"|charmbracelet.glow'
    'go|go@|go@|GoLang.Go'
    'node|node@|node@|CoreyButler.NVMforWindows'
    'gping|package:gping|brew "gping"|orf.gping'
    'helm|package:helm|brew "helm"|Helm.Helm'
    'herdr|release:herdr|brew "herdr"|HERDR_WINDOWS_PREVIEW_TAG'
    'http|package:httpie|brew "httpie"|HTTPie.HTTPie'
    'hyperfine|release:hyperfine|brew "hyperfine"|sharkdp.hyperfine'
    'jq|package:jq|brew "jq"|jqlang.jq'
    'just|release:just|brew "just"|Casey.Just'
    'kubectl|package:kubectl|brew "kubectl"|Kubernetes.kubectl'
    'lazygit|release:lazygit|brew "lazygit"|JesseDuffield.lazygit'
    'mlr|package:miller|brew "miller"|Miller.Miller'
    'nvim|release:neovim|brew "neovim"|Neovim.Neovim'
    'procs|package:procs|brew "procs"|dalance.procs'
    'rg|package:ripgrep|brew "ripgrep"|BurntSushi.ripgrep.MSVC'
    'shellcheck|package:shellcheck|brew "shellcheck"|koalaman.shellcheck'
    'spf|release:superfile|brew "superfile"|yorukot.superfile'
    'tldr|package:tealdeer|brew "tealdeer"|dbrgn.tealdeer'
    'xh|package:xh|brew "xh"|ducaale.xh'
    'yazi|release:yazi|brew "yazi"|sxyazi.yazi'
    'zoxide|release:zoxide|brew "zoxide"|ajeetdsouza.zoxide'
    'codex|@openai/codex|cask "codex"|OpenAI.Codex'
    'claude|@anthropic-ai/claude-code|cask "claude-code"|Anthropic.ClaudeCode'
    'copilot|@github/copilot|@github/copilot|GitHub.Copilot'
    'pi|@earendil-works/pi-coding-agent|brew "pi-coding-agent"|EarendilWorks.pi'
)

for declaration in "${tool_declarations[@]}"; do
    IFS='|' read -r command linux_token macos_token windows_token <<< "$declaration"
    linux_declared "$linux_token" || fail "$command is missing from Linux packages"
    contains "$macos_token" "${MACOS_FILES[@]}" || fail "$command is missing from macOS packages"
    contains "$windows_token" "${WINDOWS_FILES[@]}" || fail "$command is missing from Windows packages"
done

echo "Cross-platform CLI declarations are synchronized."
