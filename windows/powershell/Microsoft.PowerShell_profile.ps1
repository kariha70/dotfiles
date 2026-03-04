# Managed by dotfiles bootstrap.ps1
# Source of truth: windows/powershell/Microsoft.PowerShell_profile.ps1

# --- XDG Base Directory paths (required for direnv and others on Windows) ---
if (-not $env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME = "$env:USERPROFILE\.config" }
if (-not $env:XDG_DATA_HOME) { $env:XDG_DATA_HOME = "$env:USERPROFILE\.local\share" }
if (-not $env:XDG_CACHE_HOME) { $env:XDG_CACHE_HOME = "$env:USERPROFILE\.cache" }
if (-not $env:XDG_STATE_HOME) { $env:XDG_STATE_HOME = "$env:USERPROFILE\.local\state" }

# --- Command existence cache (avoid repeated Get-Command calls) ---
$_cmdCache = @{}
function Test-Cmd {
    param([string]$Name)
    if (-not $_cmdCache.ContainsKey($Name)) {
        $_cmdCache[$Name] = $null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue)
    }
    return $_cmdCache[$Name]
}

# --- Shell init caching ---
# Cache subprocess output to files, regenerate weekly or on demand via Update-ShellCache
$_shellCacheDir = "$env:LOCALAPPDATA\powershell-cache"
if (-not (Test-Path $_shellCacheDir)) { New-Item -ItemType Directory -Path $_shellCacheDir -Force | Out-Null }
$_cacheMaxAge = (Get-Date).AddDays(-7)

function _Get-CachedInit {
    param([string]$Name, [scriptblock]$Generator)
    $cacheFile = "$_shellCacheDir\$Name.ps1"
    $tmpFile = "$cacheFile.tmp"
    $needsRefresh = -not (Test-Path $cacheFile) -or (Get-Item $cacheFile).LastWriteTime -lt $_cacheMaxAge

    if ($needsRefresh) {
        try {
            $output = & $Generator 2>&1
            if ($LASTEXITCODE -eq 0) {
                $output | Out-File -FilePath $tmpFile -Encoding utf8 -Force
                Move-Item -LiteralPath $tmpFile -Destination $cacheFile -Force
            }
            else {
                Write-Warning "Skipping cache update for '$Name' (exit $LASTEXITCODE)."
            }
        }
        catch {
            Remove-Item -LiteralPath $tmpFile -Force -ErrorAction SilentlyContinue
            Write-Warning "Skipping cache update for '$Name': $($_.Exception.Message)"
        }
    }

    if (Test-Path $cacheFile) {
        try {
            & {
                $ErrorActionPreference = "Stop"
                . $cacheFile
            }
        }
        catch {
            Write-Warning "Skipping cached init for '$Name': $($_.Exception.Message)"
        }
    }
}

function Update-ShellCache {
    Remove-Item "$_shellCacheDir\*.ps1" -Force -ErrorAction SilentlyContinue
    Write-Host "Shell init cache cleared. Restart your shell to regenerate." -ForegroundColor Yellow
}

# --- PSReadLine ---
# Guard against non-interactive hosts (bootstrap/scripts/redirected output).
$canUsePSReadLine = $Host.Name -eq "ConsoleHost" -and -not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected
if ($canUsePSReadLine -and (Get-Module -ListAvailable -Name PSReadLine)) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
    try {
        # InlineView gives ghost-text suggestions without clashing with Atuin's TUI.
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -PredictionViewStyle InlineView
        Set-PSReadLineOption -HistorySearchCursorMovesToEnd
        # Atuin owns UpArrow and Ctrl+R for history search — don't compete.
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
        Set-PSReadLineKeyHandler -Key "Ctrl+f" -Function ForwardWord
    }
    catch {
        Write-Verbose "Skipping PSReadLine customization: $($_.Exception.Message)"
    }
}

# --- Modules (lazy-loaded for faster startup) ---
$_modulesLoaded = $false
function _Load-Modules {
    if ($script:_modulesLoaded) { return }
    $script:_modulesLoaded = $true
    Import-Module Terminal-Icons -ErrorAction SilentlyContinue
    Import-Module PSFzf -ErrorAction SilentlyContinue
    if (Get-Command -Name Set-PsFzfOption -ErrorAction SilentlyContinue) {
        # Atuin owns Ctrl+R for history search; PSFzf handles Ctrl+T for file finding only.
        Set-PsFzfOption -PSReadlineChordProvider "Ctrl+t"
    }

    # Init Atuin after modules so its keybindings (Ctrl+R, UpArrow) always win.
    if (Test-Cmd -Name "atuin" -and (Get-Module -Name PSReadLine)) {
        _Get-CachedInit "atuin" { atuin init powershell }
    }
}
# Defer module loading until first prompt
if ($Host.Name -eq "ConsoleHost") {
    Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action { _Load-Modules } | Out-Null
}

# --- Cached shell inits ---
if (Test-Cmd -Name "zoxide") {
    _Get-CachedInit "zoxide" { zoxide init powershell }
}

if (Test-Cmd -Name "direnv") {
    _Get-CachedInit "direnv" { direnv hook pwsh 2>&1 | Where-Object { $_ -is [string] } }
}

if (Test-Cmd -Name "eza") {
    Set-Alias -Name ls -Value eza -Option AllScope -Force

    function ll {
        eza -al --icons --git @Args
    }

    function la {
        eza -a --icons @Args
    }

    function lt {
        eza --tree --level=2 --icons @Args
    }
}

if (Test-Cmd -Name "bat") {
    Set-Alias -Name cat -Value bat -Option AllScope -Force
}

if (Test-Cmd -Name "nvim") {
    Set-Alias -Name vim -Value nvim -Option AllScope -Force
    Set-Alias -Name v -Value nvim -Option AllScope -Force
}

if (Test-Cmd -Name "git") {
    Set-Alias -Name g -Value git -Option AllScope -Force

    function gs { git status @Args }
    function ga { git add @Args }
    function gc { git commit @Args }
    function gcm { git commit -m @Args }
    function gd { git diff @Args }
    function gco { git checkout @Args }
    function gb { git branch @Args }
    function gl { git log --oneline --graph --decorate @Args }
    function gp { git pull @Args }
}

if (Test-Cmd -Name "lazygit") {
    function lg { lazygit @Args }
}

if (Test-Cmd -Name "yazi") {
    function y {
        $tmp = Join-Path -Path $env:TEMP -ChildPath ("yazi-cwd-" + [System.Guid]::NewGuid().ToString() + ".txt")
        yazi @Args --cwd-file="$tmp"
        if (Test-Path -LiteralPath $tmp) {
            $cwd = (Get-Content -LiteralPath $tmp -Raw).Trim()
            Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
            if (-not [string]::IsNullOrWhiteSpace($cwd) -and (Test-Path -LiteralPath $cwd -PathType Container)) {
                Set-Location -LiteralPath $cwd
            }
        }
    }
}

if (Test-Cmd -Name "kubectl") {
    function k { kubectl @Args }
}

function .. { Set-Location .. }
function ... { Set-Location ../.. }

if (Test-Cmd -Name "starship") {
    _Get-CachedInit "starship" { starship init powershell }
}
