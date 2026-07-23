Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path -Path $ScriptDir -ChildPath "lib/helpers.ps1")

if (-not $IsWindows) {
    throw "install/ai-tools.ps1 is intended for Windows hosts."
}

Write-Step "Installing AI coding tools..."

$aiPackages = @(
    @{ Id = "OpenAI.Codex"; Name = "Codex CLI" },
    @{ Id = "Anthropic.ClaudeCode"; Name = "Claude Code" },
    @{ Id = "GitHub.Copilot"; Name = "GitHub Copilot CLI" }
)

foreach ($pkg in $aiPackages) {
    Install-WithWinget -Id $pkg.Id -Name $pkg.Name | Out-Null
}

if (Test-CommandExist -Name "herdr") {
    Write-Step "Herdr is already installed."
} else {
    $versions = Get-VersionsMap
    $previewTag = [string]$versions["HERDR_WINDOWS_PREVIEW_TAG"]
    $expectedSha = [string]$versions["HERDR_WINDOWS_BINARY_SHA256_x86_64"]

    if ([string]::IsNullOrWhiteSpace($previewTag)) {
        throw "HERDR_WINDOWS_PREVIEW_TAG is missing. Run scripts/bump-versions.sh."
    }
    if ($previewTag -notmatch "^preview-[0-9A-Za-z._-]+$") {
        throw "HERDR_WINDOWS_PREVIEW_TAG has an invalid format: $previewTag"
    }

    $architecture = Get-ArchitectureToken
    if ($architecture -eq "arm64") {
        Write-Step "Windows ARM64 detected; installing the Herdr x86_64 build under emulation."
    }

    $assetUrl = "https://github.com/ogulcancelik/herdr/releases/download/$previewTag/herdr-windows-x86_64.exe"
    $installDir = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Programs\Herdr\bin"
    $destination = Join-Path -Path $installDir -ChildPath "herdr.exe"
    $tempFile = Join-Path -Path $env:TEMP -ChildPath ("herdr-" + [System.Guid]::NewGuid().ToString("N") + ".exe")

    try {
        Ensure-Directory -Path $installDir
        Invoke-DownloadFile -Url $assetUrl -Destination $tempFile
        Assert-Sha256 -Path $tempFile -ExpectedHash $expectedSha -Label "Herdr (Windows x86_64)"
        Copy-Item -LiteralPath $tempFile -Destination $destination -Force
    } finally {
        Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
    }

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $pathEntries = @($userPath -split ";" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if (-not ($pathEntries | Where-Object { [System.StringComparer]::OrdinalIgnoreCase.Equals($_, $installDir) })) {
        $newUserPath = (@($installDir) + $pathEntries) -join ";"
        [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
    }
    if (-not (($env:Path -split ";") | Where-Object { [System.StringComparer]::OrdinalIgnoreCase.Equals($_, $installDir) })) {
        $env:Path = "$installDir;$env:Path"
    }

    & $destination --version | Out-Null
    Write-Step "Herdr installed."
}

Write-Step "AI coding tools installation complete."
