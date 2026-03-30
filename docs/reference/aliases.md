# Aliases & Key Bindings

Aliases are defined in `bash/.bash_aliases` (sourced by both Bash and Zsh) and
mirrored as PowerShell functions in the Windows profile. The tables below apply
to **both** platforms unless noted otherwise.

## File Navigation (eza)

| Alias | Command | Description |
|-------|---------|-------------|
| `ls` | `eza` | Modern file listing |
| `ll` | `eza -alF --icons` | Detailed list with icons |
| `la` | `eza -a --icons` | Show hidden files |
| `lt` | `eza --tree --level=2 --icons` | Two-level tree view |

## Git Shortcuts

| Alias | Command |
|-------|---------|
| `g` | `git` |
| `gs` | `git status` |
| `ga` | `git add` |
| `gc` | `git commit` |
| `gcm` | `git commit -m` |
| `gd` | `git diff` (rendered by delta with side-by-side view) |
| `gco` | `git checkout` |
| `gb` | `git branch` |
| `gl` | `git log` (pretty graph format) |
| `gp` | `git pull` |
| `lg` | `lazygit` |

## Tools & Navigation

| Alias | Command | Description |
|-------|---------|-------------|
| `v` / `vim` | `nvim` | Neovim with LazyVim |
| `y` | `yazi` | Terminal file manager (changes directory on exit) |
| `cat` | `bat` | Syntax-highlighted output |
| `z <path>` | `zoxide` | Smart directory jump |
| `zi` | `zoxide` interactive | Interactive directory picker |
| `fp` | fzf + bat | Fuzzy find files with bat preview |
| `fe` | fzf | Fuzzy find environment variables |
| `t` / `ta` / `tn` | `tmux` / attach / new session | Tmux shortcuts |
| `c` | `clear` | Clear terminal |
| `..` / `...` | `cd ..` / `cd ../..` | Quick directory traversal |
| `k` | `kubectl` | Kubernetes CLI (if installed) |
| `py` | `python3` | Python shortcut |
| `code-p` / `code-w` | VS Code Insiders | Profile switching helpers |

## Key Bindings

| Binding | Action |
|---------|--------|
| `Ctrl+R` | Shell history search ([Atuin](https://github.com/atuinsh/atuin)) |
| `Ctrl+T` | Fuzzy file finder ([fzf](https://github.com/junegunn/fzf) / PSFzf) |
| `Ctrl+A` | Tmux prefix (replaces default `Ctrl+B`) |
| `Prefix + r` | Reload tmux configuration |

## Tmux

The tmux configuration (`tmux/.tmux.conf`) ships with the following defaults:

| Setting | Value |
|---------|-------|
| **Prefix** | `Ctrl+A` |
| **Mouse** | Enabled |
| **Window numbering** | Starts at `1` |
| **Renumber on close** | Yes — closing a window renumbers remaining windows |

::: info Cross-platform aliases
Aliases work on **Linux/macOS** (via `bash/.bash_aliases`, sourced by both
`.bashrc` and `.zshrc`) and on **Windows** (equivalent functions in the
PowerShell profile at `windows/powershell/Microsoft.PowerShell_profile.ps1`).
:::
