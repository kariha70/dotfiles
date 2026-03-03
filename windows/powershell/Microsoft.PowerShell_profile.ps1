# Managed by dotfiles bootstrap.ps1
# Source of truth: windows/powershell/Microsoft.PowerShell_profile.ps1

function Test-Cmd {
    param([string]$Name)
    return $null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue)
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
        . $cacheFile
    }
}

function Update-ShellCache {
    Remove-Item "$_shellCacheDir\*.ps1" -Force -ErrorAction SilentlyContinue
    Write-Host "Shell init cache cleared. Restart your shell to regenerate." -ForegroundColor Yellow
}

# --- PSReadLine ---
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# --- Modules ---
Import-Module Terminal-Icons -ErrorAction SilentlyContinue
Import-Module PSFzf -ErrorAction SilentlyContinue
if (Get-Command -Name Set-PsFzfOption -ErrorAction SilentlyContinue) {
    Set-PsFzfOption -PSReadlineChordProvider "Ctrl+t" -PSReadlineChordReverseHistory "Ctrl+r"
}

# --- Cached shell inits ---
if (Test-Cmd -Name "zoxide") {
    _Get-CachedInit "zoxide" { zoxide init powershell }
}

if (Test-Cmd -Name "direnv") {
    _Get-CachedInit "direnv" { direnv hook pwsh 2>$null }
}

if (Test-Cmd -Name "atuin") {
    _Get-CachedInit "atuin" { atuin init powershell }
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
