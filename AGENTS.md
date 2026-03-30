# Repository Guidelines

## Project Structure & Module Organization
- Core configs live in `bash/`, `git/`, `vim/`, and `zsh/`; each mirrors files symlinked into `$HOME`.
- `install/` holds modular installers (`packages.sh`, `ohmyzsh.sh`, `fonts.sh`, etc.) invoked by the bootstrap flow; each should be re-runnable.
- Shared shell helpers live in `install/lib/helpers.sh`; **always hard-source it** (`source "$SCRIPT_DIR/lib/helpers.sh"`) at the top of every installer — never conditionally fall back to inline definitions. It provides: `is_wsl`, `is_macos`, `is_linux`, `apt_update_once`, `ensure_local_bin`, `get_arch`, `sha256_file`, `verify_sha256`, `source_versions`, `download_and_verify`, `log_info`, `log_warn`.
- Pinned versions and checksums are centralized in `install/versions.env`; use `source_versions "$SCRIPT_DIR"` instead of inline sourcing boilerplate. For downloads, prefer `download_and_verify <url> <output> <sha> <label>`.
- Shared shell logic (used by both `.bashrc` and `.zshrc`) lives in `bash/.config/shell/` and is stowed to `~/.config/shell/`.
- `bootstrap.sh` orchestrates installs, WSL detection, stow runs, and default-shell switching.
- Adding configs: create a directory (e.g., `tmux/`), add the dotfiles, append it to `STOW_DIRS` in `bootstrap.sh`, then restow.

## Build, Test, and Development Commands
- Run from the repository root.
- Bootstrap a machine: `./bootstrap.sh` (installs, stows configs, sets the login shell).
- Iterate on one tool: `bash install/<script>.sh` (e.g., `bash install/eza.sh`) instead of the whole bootstrap.
- Restow after config edits: `stow -v -R -t "$HOME" -d "$(pwd)" bash git vim zsh`.
- Spot-check shell scripts: `shellcheck install/*.sh install/lib/helpers.sh` to catch quoting and portability issues (bootstrap installs shellcheck).

## Coding Style & Naming Conventions
- Shell scripts use Bash with `set -e`; keep commands strictly quoted, favor `command -v` checks, and gate OS-specific logic with the existing WSL detection pattern (`grep -qEi "(Microsoft|WSL)" /proc/version`).
- Keep installers idempotent; prefer appending to arrays over rewriting and guard `sudo` calls with clear messaging.
- Filenames are lowercase with hyphens; commit subjects follow the existing `feat:`, `fix:`, `chore:` style in `git log`.

## Testing Guidelines
- No automated tests; run the touched installer(s) and, when possible, the full `./bootstrap.sh` on native Linux and WSL.
- Check idempotency: rerun the touched installer or `./bootstrap.sh` to confirm a clean second pass without new backups or errors.
- Confirm stow results by checking symlinks in `$HOME` (e.g., `ls -l ~/.zshrc`) and ensuring no unintended backups appear.
- For risky edits (fonts, SSH), test in a disposable VM or container; document any manual steps in your PR.

## Commit & Pull Request Guidelines
- Use small, focused commits with imperative subjects (`feat: add ARM64 support for tool installers`); include scope when helpful.
- PRs should describe what changed, how it was verified (commands and OS), and any user-facing impacts (new tools, defaults).
- Link related issues when present, and attach terminal snippets only if they clarify behavior (e.g., WSL detection output).

## Security & Configuration Tips
- Installers call `sudo apt-get` and modify login shells; avoid secrets or machine-specific paths. Prefer env vars to tokens.
- Respect WSL/host differences: keep font installs gated to non-WSL and leave SSH changes skipped on WSL unless explicitly needed.
- For any installer that downloads a script or prebuilt archive, require a SHA256 and fail closed if it is missing or mismatched. Use `download_and_verify` from `helpers.sh` for the download+verify pattern. Existing env vars used by the scripts include: `NVM_INSTALLER_SHA256`, `BUN_INSTALLER_SHA256`, `NEOVIM_APPIMAGE_SHA256_*`, `LAZYGIT_TAR_SHA256_*`, `DELTA_DEB_SHA256_*`, `GLOW_DEB_SHA256_*`, `FASTFETCH_DEB_SHA256_*`, `YAZI_ZIP_SHA256_*`, `ATUIN_TAR_SHA256_*`, `ZOXIDE_INSTALLER_SHA256`, `UV_INSTALLER_SHA256`, `RUSTUP_INSTALLER_SHA256`, `AZURE_CLI_APT_INSTALLER_SHA256`, `EZA_KEY_FINGERPRINT`, `MESLO_*_TTF_SHA256`, `HOMEBREW_INSTALLER_SHA256`, and optional `HOMEBREW_INSTALLER_URL`.
When updating versions, download the matching release asset (or installer) and compute `sha256sum` before setting the pin.
