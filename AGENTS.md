# Repository Guidelines

## Project Structure & Module Organization
- Core configs live in `bash/`, `git/`, `vim/`, and `zsh/`; each mirrors files symlinked into `$HOME`.
- `install/` holds modular installers (`packages.sh`, `ohmyzsh.sh`, `fonts.sh`, etc.) invoked by the bootstrap flow; each should be re-runnable. Linux package paths must support both apt-based Ubuntu and pacman-based Arch Linux.
- Shared shell helpers live in `install/lib/helpers.sh`; **always hard-source it** (`source "$SCRIPT_DIR/lib/helpers.sh"`) at the top of every installer — never conditionally fall back to inline definitions. It provides: `is_wsl`, `is_macos`, `is_linux`, `apt_update_once`, `pacman_update_once`, `pacman_install`, `get_arch`, `sha256_file`, `verify_sha256`, `source_versions`, `download_and_verify`, `command_version`, `pinned_version_satisfied`, `install_verified_deb`, `fetch_apt_key`, `install_apt_source`, `resolve_mise_bin`, `mise_install_npm_tools`, `release_info`, `install_release`, `load_brew_shellenv`.
- Pinned versions and checksums are centralized in `install/versions.env`; use `source_versions "$SCRIPT_DIR"` instead of inline sourcing boilerplate. For downloads, prefer `download_and_verify <url> <output> <sha> <label>` (or `install_verified_deb` for `.deb` assets).
- GitHub release assets are described once in `install/lib/releases.sh` (`release_info`); installers, `scripts/bump-versions.sh`, and the pin checks all read it. Add new release tools there (and to `RELEASE_TOOLS`) instead of writing a new installer; `install_release <tool>` does download, verification, extraction, and installation. Release pins are named `<TOOL>_VERSION` (no leading `v`) and `<TOOL>_SHA256_{x86_64,arm64}`.
- Pinned installers must not stop at "already installed": gate them with `pinned_version_satisfied <pin> <command-or-path>...` so bumping a pin upgrades existing machines. Do not install a pinned tool from the distro package manager first on apt systems; Arch keeps using pacman.
- Shared shell logic (used by both `.bashrc` and `.zshrc`) lives in `bash/.config/shell/` and is stowed to `~/.config/shell/`.
- `bootstrap.sh` runs the installers in `INSTALL_STEPS` (each one checks whether it applies to the current platform), then stows configs, then runs `install/git-config.sh` and `install/default-shell.sh`. macOS system defaults are opt-in via `APPLY_MACOS_DEFAULTS=1`.
- Adding configs: create a directory (e.g., `tmux/`), add the dotfiles, append it to `STOW_DIRS` in `bootstrap.sh`, then restow.

## Build, Test, and Development Commands
- Run from the repository root.
- Bootstrap a machine: `./bootstrap.sh` (installs, stows configs, sets the login shell).
- Iterate on one tool: `bash install/<script>.sh` (e.g., `bash install/eza.sh`) instead of the whole bootstrap.
- Restow after config edits: `stow -v -R -t "$HOME" -d "$(pwd)" bash git vim zsh tmux nvim`.
- Spot-check shell scripts: `shellcheck install/*.sh install/lib/helpers.sh` to catch quoting and portability issues (bootstrap installs shellcheck).
- CI runs automatically on push/PR to `main`: shellcheck + PSScriptAnalyzer linting, and cross-platform bootstrap smoke tests on Ubuntu, Arch Linux, macOS, and Windows.

## Coding Style & Naming Conventions
- Shell scripts use Bash with `set -e`; keep commands strictly quoted, favor `command -v` checks, and gate OS-specific logic with the existing WSL detection pattern (`grep -qEi "(Microsoft|WSL)" /proc/version`).
- Keep installers idempotent; prefer appending to arrays over rewriting and guard `sudo` calls with clear messaging.
- Filenames are lowercase with hyphens; commit subjects follow the existing `feat:`, `fix:`, `chore:`, `perf:`, `refactor:`, `docs:` style in `git log`.

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
- Installers call `sudo apt-get` or `sudo pacman` and modify login shells; avoid secrets or machine-specific paths. Prefer env vars to tokens.
- Respect WSL/host differences: keep font installs gated to non-WSL and leave SSH changes skipped on WSL unless explicitly needed.
- For any installer that downloads a script or prebuilt archive, require a SHA256 and fail closed if it is missing or mismatched. Use `download_and_verify` from `helpers.sh` for the download+verify pattern. Pins used by the scripts include the release-asset pins from `install/lib/releases.sh` (`<TOOL>_SHA256_*`), `BUN_INSTALLER_SHA256`, `UV_INSTALLER_SHA256`, `RUSTUP_INSTALLER_SHA256`, `AZURE_CLI_APT_INSTALLER_SHA256`, `GH_APT_KEYRING_SHA256`, `GIT_CORE_PPA_KEY_FINGERPRINT`, `EZA_KEY_FINGERPRINT`, `MESLO_*_TTF_SHA256`, `HOMEBREW_INSTALLER_SHA256`, and optional `HOMEBREW_INSTALLER_URL`.
When updating versions, download the matching release asset (or installer) and compute `sha256sum` before setting the pin.
