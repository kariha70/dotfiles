# shellcheck shell=bash
# Shell functions shared by every profile, written for both bash and zsh.
#
# The default profile sources this from ~/.config/shell/common.sh; the Omarchy
# profile from ~/.config/shell/personal.sh, which reaches it through the
# symlink omarchy/.config/shell/functions.sh. Keep it free of anything that
# belongs to one profile: no PATH changes, no tool hooks, and no names that
# Omarchy defines (c, t, n, ff, ga, gd, ls, cd, ...).

# Source a tool's generated completion script, cached for a day; generating it
# costs startup time. Usage: _dotfiles_cached_completion <name> <command...>
_dotfiles_cached_completion() {
    local name="$1" shell="bash" cache tmp
    shift
    [[ -z ${ZSH_VERSION-} ]] || shell="zsh"
    cache="${XDG_CACHE_HOME:-$HOME/.cache}/shell/$name.$shell"
    if [[ ! -s $cache || -n $(find "$cache" -mmin +1440 2>/dev/null) ]]; then
        mkdir -p "${cache%/*}"
        # Write to a temporary file and rename it, so a shell starting at the
        # same time never sources a half-written script.
        tmp="$cache.$$"
        if "$@" >"$tmp" 2>/dev/null && [[ -s $tmp ]]; then
            mv -f "$tmp" "$cache"
        else
            rm -f "$tmp"
            return 0
        fi
    fi
    # shellcheck source=/dev/null
    source "$cache"
}

# yazi: change to the directory yazi was in when it exits.
y() {
    local tmp cwd
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [[ -n $cwd && $cwd != "$PWD" ]]; then
        builtin cd -- "$cwd" || return
    fi
    rm -f -- "$tmp"
}

# zsh gets extract and web search from Oh My Zsh's plugins of the same name.
[[ -n ${BASH_VERSION-} ]] || return 0

# Extract any common archive (Oh My Zsh's extract plugin).
extract() {
    local file
    if (($# == 0)); then
        echo "Usage: extract <archive>..." >&2
        return 1
    fi
    for file in "$@"; do
        if [[ ! -f $file ]]; then
            echo "extract: '$file' is not a file" >&2
            return 1
        fi
        # tr rather than ${file,,}: macOS ships bash 3.2.
        case "$(printf '%s' "$file" | tr '[:upper:]' '[:lower:]')" in
            *.tar | *.tar.gz | *.tgz | *.tar.bz2 | *.tbz2 | *.tar.xz | *.txz | *.tar.zst | *.tzst) tar -xf "$file" ;;
            *.gz) gunzip -k "$file" ;;
            *.bz2) bunzip2 -k "$file" ;;
            *.xz) unxz -k "$file" ;;
            *.zst) unzstd "$file" ;;
            *.zip | *.jar) unzip "$file" ;;
            *.7z) 7z x "$file" ;;
            *.rar) unrar x "$file" ;;
            *)
                echo "extract: unsupported archive '$file'" >&2
                return 1
                ;;
        esac || return
    done
}

# Search the web from the terminal (Oh My Zsh's web-search plugin).
web_search() {
    local engine="$1" query url opener
    shift
    query="$(jq -rn --arg q "$*" '$q | @uri')"
    case "$engine" in
        google) url="https://www.google.com/search?q=$query" ;;
        ddg) url="https://duckduckgo.com/?q=$query" ;;
        github) url="https://github.com/search?q=$query" ;;
        *)
            echo "web_search: unknown engine '$engine'" >&2
            return 1
            ;;
    esac
    if [[ -n ${BROWSER-} ]]; then
        opener="$BROWSER"
    elif command -v xdg-open &>/dev/null; then
        opener="xdg-open"
    else
        opener="open"
    fi
    # shellcheck disable=SC2086 # BROWSER may carry arguments
    $opener "$url" >/dev/null 2>&1 &
    disown
}
alias google='web_search google'
alias ddg='web_search ddg'
