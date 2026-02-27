# Managed by dotfiles bootstrap.ps1
# Source of truth: windows/powershell/Microsoft.PowerShell_profile.ps1

function Test-Cmd {
    param([string]$Name)
    return $null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue)
}

if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons -ErrorAction SilentlyContinue
}

if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf -ErrorAction SilentlyContinue
    if (Get-Command -Name Set-PsFzfOption -ErrorAction SilentlyContinue) {
        Set-PsFzfOption -PSReadlineChordProvider "Ctrl+t" -PSReadlineChordReverseHistory "Ctrl+r"
    }
}

if (Test-Cmd -Name "zoxide") {
    Invoke-Expression (& { zoxide init powershell | Out-String })
}

if (Test-Cmd -Name "direnv") {
    $direnvHook = $null
    foreach ($shell in @("pwsh", "powershell")) {
        $direnvHook = (& direnv hook $shell 2>&1 | Out-String)
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($direnvHook)) {
            Invoke-Expression $direnvHook
            break
        }
    }
}

if (Test-Cmd -Name "atuin") {
    Invoke-Expression (& { atuin init powershell | Out-String })
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
    Invoke-Expression (& { starship init powershell | Out-String })
}
