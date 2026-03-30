Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path -Path $ScriptDir -ChildPath "lib/helpers.ps1")

if (-not $IsWindows) {
    throw "install/bun.ps1 is intended for Windows hosts."
}

Write-Step "Installing bun..."

Install-WithWinget -Id "Oven-sh.Bun" -Name "bun" | Out-Null

Write-Step "bun installation complete."
