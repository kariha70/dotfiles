# mise activation (shared by bash and zsh)
# Puts the global runtimes from install/mise.sh on PATH and switches to a
# project's own versions when entering a directory with a mise.toml.

if command -v mise >/dev/null 2>&1; then
    MISE_BIN="$(command -v mise)"
elif [ -x "$HOME/.local/bin/mise" ]; then
    MISE_BIN="$HOME/.local/bin/mise"
else
    MISE_BIN=""
fi

if [ -n "$MISE_BIN" ]; then
    if [ -n "${ZSH_VERSION:-}" ]; then
        eval "$("$MISE_BIN" activate zsh)"
    elif [ -n "${BASH_VERSION:-}" ]; then
        eval "$("$MISE_BIN" activate bash)"
    fi
fi
unset MISE_BIN
