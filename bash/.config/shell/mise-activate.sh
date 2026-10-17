# mise activation (shared by bash and zsh)
# Puts the global runtimes from install/mise.sh on PATH and switches to a
# project's own versions when entering a directory with a mise.toml.

MISE_BIN=""
if command -v mise >/dev/null 2>&1; then
    MISE_BIN="$(command -v mise)"
else
    for candidate in "$HOME/.local/bin/mise" /opt/homebrew/bin/mise /usr/local/bin/mise; do
        if [ -x "$candidate" ]; then
            MISE_BIN="$candidate"
            break
        fi
    done
    unset candidate
fi

if [ -n "$MISE_BIN" ]; then
    if [ -n "${ZSH_VERSION:-}" ]; then
        eval "$("$MISE_BIN" activate zsh)"
    elif [ -n "${BASH_VERSION:-}" ]; then
        eval "$("$MISE_BIN" activate bash)"
    fi
fi
unset MISE_BIN
