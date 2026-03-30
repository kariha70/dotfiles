# Managed by dotfiles bootstrap.ps1
# Source of truth: windows/powershell/Microsoft.PowerShell_profile.ps1

# --- XDG Base Directory paths (required for direnv and others on Windows) ---
if (-not $env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME = "$env:USERPROFILE\.config" }
if (-not $env:XDG_DATA_HOME) { $env:XDG_DATA_HOME = "$env:USERPROFILE\.local\share" }
if (-not $env:XDG_CACHE_HOME) { $env:XDG_CACHE_HOME = "$env:USERPROFILE\.cache" }
if (-not $env:XDG_STATE_HOME) { $env:XDG_STATE_HOME = "$env:USERPROFILE\.local\state" }

$_cargoBin = Join-Path -Path $env:USERPROFILE -ChildPath ".cargo\bin"
if (Test-Path -LiteralPath $_cargoBin) {
    $pathEntries = $env:PATH -split ";"
    if (-not ($pathEntries | Where-Object { [System.StringComparer]::OrdinalIgnoreCase.Equals($_, $_cargoBin) })) {
        $env:PATH = "$_cargoBin;$env:PATH"
    }
}

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
# Cache slower subprocess-generated init scripts to files, regenerate weekly or on demand via Update-ShellCache.
$_shellCacheDir = "$env:LOCALAPPDATA\powershell-cache"
if (-not (Test-Path -LiteralPath $_shellCacheDir)) { New-Item -ItemType Directory -Path $_shellCacheDir -Force | Out-Null }
$_cacheMaxAge = (Get-Date).AddDays(-7)

function _Get-InitScript {
    param([string]$Name, [scriptblock]$Generator)

    try {
        $output = & $Generator 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Skipping init for '$Name' (exit $LASTEXITCODE)."
            return $null
        }

        $lines = foreach ($entry in $output) {
            if ($null -ne $entry) {
                $entry.ToString()
            }
        }
        $scriptText = ($lines -join [Environment]::NewLine).Trim()
        if ([string]::IsNullOrWhiteSpace($scriptText)) {
            return $null
        }

        return $scriptText
    }
    catch {
        Write-Warning "Skipping init for '$Name': $($_.Exception.Message)"
        return $null
    }
}

function _Get-CachedInit {
    param([string]$Name, [scriptblock]$Generator)
    $cacheFile = Join-Path -Path $_shellCacheDir -ChildPath "$Name.ps1"
    $tmpFile = "$cacheFile.tmp"
    $needsRefresh = -not (Test-Path -LiteralPath $cacheFile) -or (Get-Item -LiteralPath $cacheFile).LastWriteTime -lt $_cacheMaxAge

    if ($needsRefresh) {
        $initScript = _Get-InitScript -Name $Name -Generator $Generator
        if (-not [string]::IsNullOrWhiteSpace($initScript)) {
            try {
                Set-Content -LiteralPath $tmpFile -Value $initScript -Encoding utf8NoBOM
                Move-Item -LiteralPath $tmpFile -Destination $cacheFile -Force
            }
            catch {
                Remove-Item -LiteralPath $tmpFile -Force -ErrorAction SilentlyContinue
                Write-Warning "Skipping cache update for '$Name': $($_.Exception.Message)"
            }
        }
    }

    if (Test-Path -LiteralPath $cacheFile) {
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
    Remove-Item (Join-Path -Path $_shellCacheDir -ChildPath "*.ps1") -Force -ErrorAction SilentlyContinue
    Write-Host "Shell init cache cleared. Restart your shell to regenerate." -ForegroundColor Yellow
}

function _Invoke-GeneratedInit {
    param([string]$Name, [scriptblock]$Generator)

    $initScript = _Get-InitScript -Name $Name -Generator $Generator
    if ([string]::IsNullOrWhiteSpace($initScript)) {
        return
    }

    try {
        . ([scriptblock]::Create($initScript))
    }
    catch {
        Write-Warning "Skipping init for '$Name': $($_.Exception.Message)"
    }
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
        # Atuin owns UpArrow and Ctrl+R for history search -- don't compete.
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
        Set-PSReadLineKeyHandler -Key "Ctrl+f" -Function ForwardWord
    }
    catch {
        Write-Verbose "Skipping PSReadLine customization: $($_.Exception.Message)"
    }
}

# --- Modules (lazy-loaded for faster startup) ---
$_modulesLoaded = $false
function _Load-Module {
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
        _Invoke-GeneratedInit "atuin" { atuin init powershell }
    }
}
# Defer module loading until first prompt
if ($Host.Name -eq "ConsoleHost") {
    Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action { _Load-Module } | Out-Null
}

# --- Shell inits ---
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

function vim { nvim @Args }
function v { nvim @Args }

function g { git @Args }
function gs { git status @Args }
function ga { git add @Args }
function gc { git commit @Args }
function gcm { git commit -m @Args }
function gd { git diff @Args }
function gco { git checkout @Args }
function gb { git branch @Args }
function gl { git log --oneline --graph --decorate @Args }
function gp { git pull @Args }

function lg { lazygit @Args }

if (Test-Cmd -Name "code-insiders") {
    function code-p {
        code-insiders --user-data-dir (Join-Path -Path $HOME -ChildPath ".code-data\kariha70") @Args
    }

    function code-w {
        code-insiders --user-data-dir (Join-Path -Path $HOME -ChildPath ".code-data\michag") @Args
    }
}

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

function k { kubectl @Args }

function .. { Set-Location .. }
function ... { Set-Location ../.. }

if (Test-Cmd -Name "starship") {
    _Invoke-GeneratedInit "starship" { starship init powershell }
}
