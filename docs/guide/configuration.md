# Configuration

Customize the bootstrap behavior with environment variables, skip flags, and local Git overrides.

## Environment Variables

| Variable | Effect |
|----------|--------|
| `ONLY_STOW=1` | Skip all installers — only symlink configs |
| `SKIP_<STEP>=1` | Skip a specific step (see [full list below](#skip-flags)) |
| `APPLY_MACOS_DEFAULTS=1` | Opt-in to macOS system preferences automation |
| `EXTRA_TOOLS="pkg1 pkg2"` | Additional apt packages to install alongside defaults |
| `EXTRA_CONFLICT_FILES="path1"` | Extra files to back up before stowing |
| `BREWFILE_PATH=/path` | Override the macOS Brewfile location |
| `BREW_CLEANUP=1` | Remove unlisted Homebrew packages after install |

::: tip Stow-only mode
Run `ONLY_STOW=1 ./bootstrap.sh` to re-link configs without re-running any installers. Useful after editing a dotfile.
:::

## SKIP Flags

Use `SKIP_<STEP>=1` to disable individual bootstrap steps.

### Linux / macOS

| Flag | Skips |
|------|-------|
| `SKIP_PACKAGES` | Core apt packages |
| `SKIP_MACOS` | macOS Homebrew bundle |
| `SKIP_SSH` | SSH server setup |
| `SKIP_OHMYZSH` | Oh My Zsh + plugins + Powerlevel10k |
| `SKIP_FONTS` | MesloLGS Nerd Font installation |
| `SKIP_EZA` | eza (modern `ls`) |
| `SKIP_NVM` | Node Version Manager |
| `SKIP_BUN` | Bun runtime |
| `SKIP_NEOVIM` | Neovim AppImage |
| `SKIP_ZOXIDE` | zoxide (smart `cd`) |
| `SKIP_LAZYGIT` | lazygit TUI |
| `SKIP_UV` | uv (Python package manager) |
| `SKIP_AZURE_CLI` | Azure CLI |
| `SKIP_RUST` | Rust toolchain via rustup |
| `SKIP_WSL` | WSL-specific setup |
| `SKIP_DELTA` | git-delta pager |
| `SKIP_EXTRAS` | Extra CLI tools (bat, fd, etc.) |
| `SKIP_EXTRAS_OPS` | Ops tools (kubectl, helm) |
| `SKIP_MACOS_DEFAULTS` | macOS system preferences |
| `SKIP_STOW` | Symlink step |
| `SKIP_GIT_SIGNING` | 1Password SSH commit signing |
| `SKIP_GIT_CREDENTIALS` | GitHub credential helper |
| `SKIP_SHELL` | Default shell change |

### Windows

| Flag | Skips |
|------|-------|
| `SKIP_PACKAGES` | winget package installs |
| `SKIP_GIT_TOOLS` | Git-related tool setup |
| `SKIP_NVM` | nvm-windows |
| `SKIP_RUST` | Rust toolchain |
| `SKIP_FONTS` | Font installation |
| `SKIP_EXTRAS` | Extra tools |
| `SKIP_PROFILE` | PowerShell profile linking |
| `SKIP_LINK` (or `SKIP_STOW`) | Dotfile symlinks/junctions |

::: warning
Skipping `STOW` / `LINK` means your config files won't be updated. Only skip this if you manage symlinks manually.
:::

## Git Identity

The `.gitconfig` includes `~/.gitconfig.local` for machine-specific overrides (this file is not tracked by git).

```ini
# ~/.gitconfig.local — add your own overrides here
[user]
    name = Your Name
    email = you@example.com
```

### Automatic Git Configuration

Bootstrap auto-configures the following when the relevant tools are detected:

| Feature | Condition | Disable with |
|---------|-----------|-------------|
| **1Password SSH signing** | `op-ssh-sign` binary detected | `SKIP_GIT_SIGNING=1` |
| **GitHub credential helper** | `gh` CLI detected | `SKIP_GIT_CREDENTIALS=1` |

- **1Password SSH signing** — enables `gpg.format=ssh` for commit signing via 1Password's SSH agent
- **GitHub credential helper** — sets `gh auth` as the HTTPS credential helper for seamless `git push`/`pull`

## Adding New Config Modules

To add a new tool's configuration to the dotfiles:

1. Create a directory that mirrors the home directory structure:

```bash
mkdir -p alacritty/.config/alacritty
cp ~/.config/alacritty/alacritty.toml alacritty/.config/alacritty/alacritty.toml
```

2. Add the directory name to `STOW_DIRS` in `bootstrap.sh`

3. Restow to activate:

```bash
stow -v -R -t "$HOME" -d "$(pwd)" alacritty
```

::: tip
GNU Stow maps the directory structure inside each package to your home directory. A file at `alacritty/.config/alacritty/alacritty.toml` becomes a symlink at `~/.config/alacritty/alacritty.toml`.
:::
