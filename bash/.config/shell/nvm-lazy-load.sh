# NVM Lazy Load (shared by bash and zsh)
# Sourced by shell configs; expects NVM_DIR to be set.

nvm_resolve_default_bin() {
    local target next alias_path visited latest

    alias_path="$NVM_DIR/alias/default"
    if [ ! -f "$alias_path" ]; then
        return 1
    fi

    target="$(cat "$alias_path")"
    visited="$target"

    while [ -n "$target" ]; do
        case "$target" in
            v*|[0-9]*)
                if [ -d "$NVM_DIR/versions/node/$target/bin" ]; then
                    echo "$NVM_DIR/versions/node/$target/bin"
                    return 0
                fi
                break
                ;;
            *)
                alias_path="$NVM_DIR/alias/$target"
                if [ -f "$alias_path" ]; then
                    next="$(cat "$alias_path")"
                    case " $visited " in
                        *" $next "*) break ;;
                    esac
                    visited="$visited $next"
                    target="$next"
                    continue
                fi
                break
                ;;
        esac
    done

    if [ -d "$NVM_DIR/versions/node" ]; then
        latest="$(command ls -1 "$NVM_DIR/versions/node" 2>/dev/null | sort -V | tail -n 1)"
        if [ -n "$latest" ] && [ -d "$NVM_DIR/versions/node/$latest/bin" ]; then
            echo "$NVM_DIR/versions/node/$latest/bin"
            return 0
        fi
    fi

    return 1
}

if NVM_DEFAULT_BIN="$(nvm_resolve_default_bin)"; then
    export PATH="$NVM_DEFAULT_BIN:$PATH"
fi

nvm_lazy_load() {
    if [ -n "${ZSH_VERSION:-}" ]; then
        unfunction nvm node npm npx yarn pnpm
    else
        unset -f nvm node npm npx yarn pnpm
    fi
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    "$@"
}

for cmd in nvm node npm npx yarn pnpm; do
    eval "$cmd() { nvm_lazy_load $cmd \"\$@\"; }"
done
