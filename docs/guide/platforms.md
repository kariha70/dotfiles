# Platform Details

The dotfiles support Linux, macOS, Windows, and WSL — each with platform-specific tooling and behavior.

## Linux

Ubuntu 22.04+ and Arch Linux are supported. Bootstrap uses `apt` on Ubuntu and `pacman` on Arch. Arch-native tools come from the signed official repositories. On Ubuntu, fast-moving tools use pinned upstream releases that are **SHA256-verified** before installation and upgraded on rerun when a pin is bumped; gh comes from GitHub's official apt repository.

- Stows **6 config packages**: `bash`, `git`, `vim`, `zsh`, `tmux`, `nvim`
- Sets **Zsh** as the default login shell
- SSH server installed and enabled automatically
- Ubuntu direct downloads support **x86_64** and **arm64**
- Official Arch Linux support targets **x86_64**

::: tip Architecture support
Every direct-download installer detects the CPU architecture at runtime and fetches the correct binary. No manual flags are needed.
:::

## Omarchy

[Omarchy](https://omarchy.org/) is detected automatically (`/usr/share/omarchy`) and gets its own **Omarchy profile**. Omarchy already ships an opinionated, themed setup: bash with starship, mise, zoxide, fzf, eza, Neovim (LazyVim), tmux, a Nerd Font, gh, Node.js, uv, herdr, and the AI coding CLIs. The profile keeps all of that and only layers personal settings on top, so `omarchy theme set`, `omarchy refresh`, and `omarchy update` keep working.

**What runs**

| Step | What it does |
|------|--------------|
| `install/omarchy.sh` | Extra CLIs with `omarchy pkg add` (stow, delta, direnv, atuin, bash-preexec, just, yazi, kubectl, helm, …), Go and Bun with `omarchy install dev-env`, and `install/npm-globals.txt` |
| `install/rust.sh` | rustup from pacman (Omarchy's own dev-env pipes an unverified script) |
| `install/azure-cli.sh` | Azure CLI from pacman |
| stow `omarchy/` | `~/.config/shell/personal.sh`, `~/.config/git/dotfiles.gitconfig`, `~/.config/starship/dotfiles.toml`, `~/.config/git/ignore`, the SSH export/import helpers |
| `install/git-config.sh` | 1Password SSH signing in `~/.gitconfig.local` (keeps Omarchy's gh credential helper) |
| `install/omarchy-config.sh` | Sources `personal.sh` at the end of Omarchy's `~/.bashrc` and includes `dotfiles.gitconfig` from `~/.config/git/config` (once each) |

**What is skipped**: Oh My Zsh, Powerlevel10k, MesloLGS font, the zsh login shell, the `bash`/`zsh`/`git`/`tmux`/`nvim`/`vim` stow packages, pinned tmux/Neovim/eza/release-tool installs, gh, uv, the AI CLI installer, the pinned Node.js/Go runtimes, and the SSH server (run `bash install/ssh.sh` if you want one).

**Bash instead of zsh**: everything the zsh setup provides is available in bash:

| zsh setup | Omarchy profile (bash) |
|-----------|------------------------|
| Powerlevel10k | starship, one line, with `~/.config/starship/dotfiles.toml` (via `STARSHIP_CONFIG`; ANSI colors, so Omarchy themes apply; right side needs ble.sh; `DOTFILES_STARSHIP=0` keeps Omarchy's prompt) |
| Oh My Zsh history/completion | Omarchy's bash defaults + bash-completion |
| `fzf` plugin | Omarchy's fzf key bindings (`Ctrl+T`, `Alt+C`), `fd --hidden` as source |
| `extract`, `web-search` plugins | `extract`, `google`, `ddg` functions (`functions.sh`, shared with the default profile's bash) |
| `git` plugin aliases | `gs gc gco gb gp gl` + Omarchy's `g gcm gcam gcad` |
| atuin (`Ctrl+R`) | atuin via bash-preexec |
| zsh-autosuggestions, zsh-syntax-highlighting | [ble.sh](https://github.com/akinomyoga/ble.sh) 0.4 (`blesh-git`), opt-in from the AUR: `OMARCHY_BLESH=1 ./bootstrap.sh` |
| direnv, kubectl/gh completions, `y` (yazi), `k`, `lg`, `ll`/`la`/`l`, `fp`, `cat`→bat | Same, in `personal.sh` |

Omarchy's own names win: `ls`/`lt` (eza), `cd` (zoxide), `t` (tmux `Work` session), `c` (opencode), `n` (nvim), `ff`, and the `ga`/`gd` worktree functions are not redefined.

Use `DOTFILES_PROFILE=default ./bootstrap.sh` to force the full cross-platform profile instead, or `DOTFILES_PROFILE=omarchy` to force this one.

## WSL

Auto-detected via `/proc/version`. WSL-specific behavior adjusts the bootstrap to work within the Windows Subsystem for Linux constraints.

- **Skips** SSH server and font installation (use the Windows host for these)
- **Configures** Git to use the Windows Credential Manager
- **Installs** `wslu` for Windows integration utilities
- **Installs** Azure CLI via the dedicated apt-based installer

::: tip Fonts on WSL
Since WSL runs inside a Windows terminal, install fonts on the **Windows side**. The dotfiles Windows bootstrap or a manual MesloLGS NF install handles this.
:::

## macOS

Uses **Homebrew** and a declarative `install/Brewfile` for all tools. Bootstrap exits with instructions if `brew` is not found.

- All CLI tools come from Homebrew — no manual downloads needed
- **Meslo Nerd Font** installed via `font-meslo-lg-nerd-font` cask
- Includes **Ghostty**, **Zed**, and **VS Code Insiders** casks
- Optional system defaults automation:

```bash
APPLY_MACOS_DEFAULTS=1 ./bootstrap.sh
```

### macOS Defaults

When `APPLY_MACOS_DEFAULTS=1` is set, bootstrap configures:

| Area | What changes |
|------|-------------|
| **Finder** | Show file extensions, show path bar |
| **Dock** | Autohide enabled, smaller icons |
| **Keyboard** | Fast key repeat rate |
| **Screenshots** | PNG format, saved to `~/Screenshots` |

::: warning
macOS defaults require a logout or restart to take full effect.
:::

## Windows (PowerShell 7+)

Parallel bootstrap flow using `winget` and PowerShell modules.

- Installs tools via **winget** (idempotent — safe to re-run)
- Links dotfiles with **symlinks/junctions**; falls back to **managed copies** when restricted
- Managed copies are tracked via **`.dotfiles-managed`** sidecar markers
- Configures **Starship** prompt, **PSReadLine** predictions, and **module lazy-loading**

::: tip Managed-copy fallback
When symlinks or junctions aren't available (e.g., no developer mode), bootstrap copies the file and places a `.dotfiles-managed` marker next to it. Re-running bootstrap updates managed copies automatically.
:::
