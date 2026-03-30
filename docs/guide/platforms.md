# Platform Details

The dotfiles support Linux, macOS, Windows, and WSL — each with platform-specific tooling and behavior.

## Linux (Ubuntu 22.04+)

The primary platform. Bootstrap installs packages via `apt`, then layers on direct-download tools (Neovim AppImage, lazygit, delta, yazi, atuin, etc.) — all **SHA256-verified**.

- Stows **6 config packages**: `bash`, `git`, `vim`, `zsh`, `tmux`, `nvim`
- Sets **Zsh** as the default login shell
- SSH server installed and enabled automatically
- Supports both **x86_64** and **arm64** architectures

::: tip Architecture support
Every direct-download installer detects the CPU architecture at runtime and fetches the correct binary. No manual flags needed.
:::

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
