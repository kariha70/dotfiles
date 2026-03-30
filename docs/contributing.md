# Contributing

Thanks for considering a contribution! This page covers everything you need to know about working with this repo.

## Project Structure

```
dotfiles/
├── bootstrap.sh              # Linux / macOS entry point
├── bootstrap.ps1             # Windows entry point
├── bash/                     # Bash config (stowed → ~/)
├── zsh/                      # Zsh config (stowed → ~/)
├── git/                      # Git config (stowed → ~/)
├── vim/                      # Vim config (stowed → ~/)
├── nvim/                     # Neovim config (stowed → ~/.config/nvim)
├── tmux/                     # Tmux config (stowed → ~/)
├── windows/                  # Windows-only configs
├── install/                  # Modular installers
│   ├── lib/
│   │   ├── helpers.sh        # Platform detection, SHA256, downloads
│   │   └── helpers.ps1       # PowerShell: winget wrapper, link helpers
│   ├── versions.env          # Pinned versions + SHA256 checksums
│   ├── versions.ps1          # PowerShell version definitions
│   ├── Brewfile              # macOS Homebrew manifest
│   ├── packages.sh           # Core apt packages
│   ├── ohmyzsh.sh            # Oh My Zsh + plugins + Powerlevel10k
│   ├── fonts.sh              # MesloLGS Nerd Font
│   └── *.sh / *.ps1          # Individual tool installers
├── scripts/
│   ├── bump-versions.sh      # Update versions + checksums
│   └── bump-versions.ps1     # Sync PS versions from env
├── .github/
│   ├── workflows/            # CI: lint + bootstrap smoke tests
│   └── copilot-instructions.md
├── AGENTS.md                 # AI assistant / contributor guidelines
└── docs/                     # VitePress documentation site
```

Each top-level directory (e.g. `bash/`, `git/`, `zsh/`) mirrors the structure of `$HOME` and is symlinked via [GNU Stow](https://www.gnu.org/software/stow/). Shared shell logic lives in `bash/.config/shell/` and is stowed to `~/.config/shell/`.

## Coding Style

### Shell scripts

- Use Bash with `set -e` and `set -o pipefail` at the top of every script.
- Keep commands **strictly quoted** — no unquoted variable expansions.
- Prefer `command -v` checks over `which` for detecting installed tools.
- Gate OS-specific logic with WSL detection: `grep -qEi "(Microsoft|WSL)" /proc/version`.

### Filenames

- Lowercase with hyphens (e.g. `extras-ops.sh`, `bump-versions.sh`).

### Installer rules

::: tip Always hard-source helpers.sh
Every installer **must** source `install/lib/helpers.sh` at the top — never conditionally fall back to inline definitions.
:::

- Use `source_versions "$SCRIPT_DIR"` to load pinned versions and checksums from `versions.env`.
- Use `download_and_verify` for **all** downloads — never download without SHA256 verification.
- Keep installers **idempotent**: prefer appending to arrays over rewriting, and guard `sudo` calls with clear messaging.

### Linting

Run ShellCheck before committing:

```bash
shellcheck install/*.sh install/lib/helpers.sh
```

CI runs ShellCheck and PSScriptAnalyzer automatically on every push and PR.

## Commit Conventions

Use small, focused commits with **imperative mood** subjects and a category prefix:

| Prefix | Use for |
|--------|---------|
| `feat:` | New features or tools |
| `fix:` | Bug fixes |
| `chore:` | Maintenance, dependency bumps |
| `docs:` | Documentation changes |
| `refactor:` | Code restructuring without behavior changes |
| `perf:` | Performance improvements |

**Examples:**

```
feat: add ARM64 support for tool installers
fix: correct stow target for nvim config
chore: bump lazygit to v0.42.0
docs: add VitePress contributing guide
refactor: extract download logic into helpers.sh
```

Include scope when helpful (e.g. `feat(macos): add Dock autohide default`). PRs should describe what changed, how it was verified, and any user-facing impacts.

## Testing

There is no automated test suite — manual verification is required.

1. **Run the touched installer(s)** directly:
   ```bash
   bash install/eza.sh
   ```

2. **Test idempotency** — rerun the same script and confirm a clean second pass with no new backups or errors:
   ```bash
   bash install/eza.sh   # second run should be a no-op
   ```

3. **Check stow symlinks** in `$HOME`:
   ```bash
   ls -l ~/.zshrc ~/.gitconfig ~/.vimrc
   ```
   Ensure no unintended `.bak` backups appear.

4. **Full bootstrap** when possible:
   ```bash
   ./bootstrap.sh
   ```

::: tip Risky edits
For changes to fonts, SSH, or login shell logic, test in a **disposable VM or container** first. Document any manual verification steps in your PR.
:::

## Installer Pattern

Every installer in `install/` should follow this canonical template:

```bash
#!/bin/bash
set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"
source_versions "$SCRIPT_DIR"
```

From there, use the helper functions for platform detection, architecture checks, and verified downloads. For example:

```bash
if is_wsl; then
    log_info "Skipping fonts on WSL"
    exit 0
fi

ARCH="$(get_arch)"
download_and_verify "$URL" "$OUTPUT_FILE" "$EXPECTED_SHA" "tool-name"
```

## Key Helper Functions

The following functions are provided by `install/lib/helpers.sh`:

| Function | Description |
|----------|-------------|
| `is_wsl` | Returns true if running under Windows Subsystem for Linux |
| `is_macos` | Returns true if running on macOS |
| `is_linux` | Returns true if running on Linux (including WSL) |
| `get_arch` | Returns the system architecture (`x86_64` or `aarch64`) |
| `apt_update_once` | Runs `sudo apt-get update` at most once per session |
| `ensure_local_bin` | Creates `~/.local/bin` and ensures it's on `$PATH` |
| `source_versions` | Sources `versions.env` from the given directory |
| `download_and_verify` | Downloads a file and verifies its SHA256 checksum; fails if mismatched |
| `log_info` | Logs an informational message with consistent formatting |
| `log_warn` | Logs a warning message with consistent formatting |

::: tip Checksums are mandatory
Every download **must** have a SHA256 checksum pinned in `install/versions.env`. Use `download_and_verify` — it will fail closed if the checksum is missing or doesn't match. When bumping versions, download the new asset and run `sha256sum` before updating the pin.
:::

## AI Assistants

This repository includes context files for AI coding assistants:

- **[`AGENTS.md`](https://github.com/kariha70/dotfiles/blob/main/AGENTS.md)** — repo conventions, coding style, and testing expectations used by AI agents.
- **[`.github/copilot-instructions.md`](https://github.com/kariha70/dotfiles/blob/main/.github/copilot-instructions.md)** — additional context for GitHub Copilot.

If you're using an AI assistant to contribute, these files provide the necessary context for consistent, high-quality changes.
