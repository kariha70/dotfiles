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
    @{ Id = "GitHub.Copilot"; Name = "GitHub Copilot CLI" },
    @{ Id = "EarendilWorks.pi"; Name = "Pi Coding Agent" }
)

foreach ($pkg in $aiPackages) {
    Install-WithWinget -Id $pkg.Id -Name $pkg.Name | Out-Null
}

$versions = Get-VersionsMap
$previewTag = [string]$versions["HERDR_WINDOWS_PREVIEW_TAG"]
$installDir = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Programs\Herdr\bin"
$destination = Join-Path -Path $installDir -ChildPath "herdr.exe"
# Records the installed preview tag so bumping the pin upgrades Herdr on rerun.
$versionMarker = Join-Path -Path $installDir -ChildPath "herdr.dotfiles-version"
$installedTag = ""
if (Test-Path -LiteralPath $versionMarker) {
    $markerContent = Get-Content -LiteralPath $versionMarker -Raw
    if ($markerContent) {
        $installedTag = $markerContent.Trim()
    }
}
$herdrCommand = Get-Command -Name "herdr" -ErrorAction SilentlyContinue

if ($herdrCommand -and -not (Test-PathEquivalent -Left $herdrCommand.Source -Right $destination)) {
    Write-Step "Herdr is already installed outside dotfiles management: $($herdrCommand.Source)"
} elseif ((Test-Path -LiteralPath $destination) -and $installedTag -eq $previewTag) {
    Write-Step "Herdr $previewTag is already installed."
} else {
    $assetName = [string]$versions["HERDR_WINDOWS_ASSET"]
    $expectedSha = [string]$versions["HERDR_WINDOWS_BINARY_SHA256_x86_64"]

    if ([string]::IsNullOrWhiteSpace($previewTag)) {
        throw "HERDR_WINDOWS_PREVIEW_TAG is missing. Run scripts/bump-versions.sh."
    }
    if ($previewTag -notmatch "^preview-[0-9A-Za-z._-]+$") {
        throw "HERDR_WINDOWS_PREVIEW_TAG has an invalid format: $previewTag"
    }
    if ($assetName -notin @("herdr-windows-x86_64.exe", "herdr-windows-x86_64.zip")) {
        throw "HERDR_WINDOWS_ASSET has an unsupported value: $assetName"
    }

    $architecture = Get-ArchitectureToken
    if ($architecture -eq "arm64") {
        Write-Step "Windows ARM64 detected; installing the Herdr x86_64 build under emulation."
    }

    $assetUrl = "https://github.com/herdrdev/herdr/releases/download/$previewTag/$assetName"
    $tempRoot = Join-Path -Path $env:TEMP -ChildPath ("herdr-" + [System.Guid]::NewGuid().ToString("N"))
    $tempFile = "$tempRoot$([System.IO.Path]::GetExtension($assetName))"

    try {
        Ensure-Directory -Path $installDir
        Invoke-DownloadFile -Url $assetUrl -Destination $tempFile
        Assert-Sha256 -Path $tempFile -ExpectedHash $expectedSha -Label "Herdr (Windows x86_64)"

        # A running herdr.exe cannot be overwritten, but it can be renamed.
        if (Test-Path -LiteralPath $destination) {
            $staleExecutable = "$destination.old"
            Remove-Item -LiteralPath $staleExecutable -Force -ErrorAction SilentlyContinue
            Move-Item -LiteralPath $destination -Destination $staleExecutable -Force
        }

        if ($assetName.EndsWith(".zip", [System.StringComparison]::OrdinalIgnoreCase)) {
            Expand-Archive -LiteralPath $tempFile -DestinationPath $tempRoot
            $archiveExecutable = Join-Path -Path $tempRoot -ChildPath "herdr.exe"
            if (-not (Test-Path -LiteralPath $archiveExecutable -PathType Leaf)) {
                throw "Herdr archive does not contain herdr.exe at its root."
            }
            Copy-Item -Path (Join-Path -Path $tempRoot -ChildPath "*") -Destination $installDir -Recurse -Force
        } else {
            Copy-Item -LiteralPath $tempFile -Destination $destination -Force
        }
    } finally {
        Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
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
    Set-Content -LiteralPath $versionMarker -Value $previewTag -Encoding utf8NoBOM
    Write-Step "Herdr $previewTag installed."
}

Write-Step "AI coding tools installation complete."
