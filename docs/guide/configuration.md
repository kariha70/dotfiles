# Configuration

Customize the bootstrap behavior with environment variables, skip flags, and local Git overrides.

## Environment Variables

| Variable | Effect |
|----------|--------|
| `ONLY_STOW=1` | Skip all installers — only symlink configs |
| `SKIP_<STEP>=1` | Skip a specific step (see [full list below](#skip-flags)) |
| `APPLY_MACOS_DEFAULTS=1` | Opt-in to macOS system preferences automation |
| `EXTRA_TOOLS="pkg1 pkg2"` | Additional apt or pacman packages to install alongside defaults |
| `EXTRA_CONFLICT_FILES="path1"` | Extra files to back up before stowing |
| `BREWFILE_PATH=/path` | Override the macOS Brewfile location |
| `BREW_CLEANUP=1` | Remove unlisted Homebrew packages after install |
| `UPGRADE_PACKAGES=1` | Also upgrade already-installed apt, Homebrew, and winget packages (pinned tools always upgrade to their pin) |
| `GIT_FROM_PPA=1` | Ubuntu only: install Git from the git-core PPA instead of the distro package |

::: tip Stow-only mode
Run `ONLY_STOW=1 ./bootstrap.sh` to re-link configs without re-running any installers. Useful after editing a dotfile.
:::

## SKIP Flags

Use `SKIP_<STEP>=1` to disable individual bootstrap steps.

### Linux / macOS

| Flag | Skips |
|------|-------|
| `SKIP_MACOS` | macOS Homebrew bundle |
| `SKIP_PACKAGES` | Base apt or pacman packages |
| `SKIP_GIT_PPA` | Opt-in git-core PPA step |
| `SKIP_GH` | GitHub CLI from the official apt repository |
| `SKIP_SSH` | SSH server setup |
| `SKIP_OHMYZSH` | Oh My Zsh + plugins + Powerlevel10k |
| `SKIP_FONTS` | MesloLGS Nerd Font installation |
| `SKIP_MISE` | mise with the pinned Node.js and Go runtimes and global npm CLIs |
| `SKIP_BUN` | Bun runtime |
| `SKIP_RELEASE_TOOLS` | All pinned release tools (just, lazygit, fzf, zoxide, delta, bat, fd, hyperfine, glow, fastfetch, atuin, yazi, superfile) |
| `SKIP_<TOOL>` | One release tool, e.g. `SKIP_LAZYGIT` or `SKIP_FZF` |
| `SKIP_TMUX` | Pinned tmux source build |
| `SKIP_NEOVIM` | Neovim AppImage |
| `SKIP_EZA` | eza (modern `ls`) |
| `SKIP_UV` | uv (Python package manager) |
| `SKIP_AZURE_CLI` | Azure CLI |
| `SKIP_AI_TOOLS` | Herdr, Codex, Claude Code, GitHub Copilot CLI, and Pi |
| `SKIP_RUST` | Rust toolchain via rustup |
| `SKIP_WSL` | WSL-specific setup |
| `SKIP_MACOS_DEFAULTS` | macOS system preferences (also requires `APPLY_MACOS_DEFAULTS=1` to run) |
| `SKIP_STOW` | Symlink step |
| `SKIP_GIT_CONFIG` | All local Git configuration below |
| `SKIP_GIT_SIGNING` | 1Password SSH commit signing |
| `SKIP_GIT_CREDENTIALS` | GitHub credential helper |
| `SKIP_SHELL` | Default shell change |

### Windows

| Flag | Skips |
|------|-------|
| `SKIP_PACKAGES` | winget package installs |
| `SKIP_GIT_TOOLS` | Git-related tool setup |
| `SKIP_NVM` | nvm-windows |
| `SKIP_AI_TOOLS` | Herdr, Codex, Claude Code, and GitHub Copilot CLI |
| `SKIP_RUST` | Rust toolchain |
| `SKIP_FONTS` | Font installation |
| `SKIP_EXTRAS` | Extra tools |
| `SKIP_PROFILE` | PowerShell profile linking |
| `SKIP_LINK` (or `SKIP_STOW`) | Dotfile symlinks/junctions |

::: warning
Skipping `STOW` / `LINK` means your config files won't be updated. Only skip this if you manage symlinks manually.
:::

## Global npm CLIs

Global npm packages are installed as [mise npm tools](https://mise.jdx.dev/dev-tools/backends/npm.html),
each in its own directory, so they survive Node.js version changes and are
reinstalled automatically on every machine. Do not use `npm install -g`.

- **AI coding CLIs** (Codex, Claude Code, Copilot, Pi) are declared in `install/ai-tools.sh`.
- **Everything else** goes in `install/npm-globals.txt`, one package per line.
  Append `allow-builds` when a package needs its own install scripts, which mise
  skips by default.
- **Migrating from nvm:** run `scripts/import-npm-globals.sh` once per machine to
  copy the existing global packages into the list, review it, and commit.

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
