Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path -Path $ScriptDir -ChildPath "lib/helpers.ps1")

if (-not $IsWindows) {
    throw "install/rust.ps1 is intended for Windows hosts."
}

Write-Step "Installing Rust via rustup..."

Install-WithWinget -Id "Rustlang.Rustup" -Name "rustup" | Out-Null

Write-Step "Rust installation complete."
