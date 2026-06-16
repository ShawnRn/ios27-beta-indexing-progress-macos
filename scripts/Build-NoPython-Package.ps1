<# 
.SYNOPSIS
Builds a no-Python-install Windows package.

.DESCRIPTION
This script is for the maintainer, not end users. It creates a local build
environment, installs PyInstaller and pymobiledevice3 there, builds
IosIndexingProgress.exe, then creates iOS_Indexing_Checker_Windows_NoPython.zip.
#>

[CmdletBinding()]
param(
    [string]$Python = "python",
    [string]$BuildRoot
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path -LiteralPath (Join-Path $scriptDir "..")).Path
if ([string]::IsNullOrWhiteSpace($BuildRoot)) {
    $dRoot = "D:\Codex Program"
    if (Test-Path -LiteralPath $dRoot) {
        $BuildRoot = Join-Path $dRoot "ios-indexing-checker-build"
    }
    else {
        $BuildRoot = Join-Path $projectRoot ".build-nopython"
    }
}

$buildRoot = $BuildRoot
$venv = Join-Path $buildRoot "venv"
$venvPython = Join-Path $venv "Scripts\python.exe"
$source = Join-Path $projectRoot "src\IosIndexingProgress.py"
$dist = Join-Path $buildRoot "dist"
$exe = Join-Path $dist "IosIndexingProgress.exe"
$packageDir = Join-Path $buildRoot "package"
$outExe = Join-Path $packageDir "IosIndexingProgress.exe"
$zipDir = Join-Path $projectRoot "dist"
$zip = Join-Path $zipDir "iOS_Indexing_Checker_Windows_NoPython.zip"
$packageReadme = Join-Path $projectRoot "packaging\README_OneClick_Distribution.txt"

if (-not (Test-Path -LiteralPath $source)) {
    throw "Missing source: $source"
}

if (-not (Test-Path -LiteralPath $venvPython)) {
    New-Item -ItemType Directory -Force -Path $buildRoot | Out-Null
    & $Python -m venv $venv
    if ($LASTEXITCODE -ne 0) {
        throw "Could not create build environment."
    }
}

& $venvPython -m pip install -U pip wheel pyinstaller pymobiledevice3
if ($LASTEXITCODE -ne 0) {
    throw "Could not install build dependencies."
}

& $venvPython -m PyInstaller `
    --clean `
    --onefile `
    --name IosIndexingProgress `
    --runtime-tmpdir . `
    --distpath $dist `
    --workpath (Join-Path $buildRoot "work") `
    --specpath $buildRoot `
    $source

if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $exe)) {
    throw "PyInstaller did not produce IosIndexingProgress.exe."
}

if (Test-Path -LiteralPath $zip) {
    Remove-Item -Force -LiteralPath $zip
}

if (Test-Path -LiteralPath $packageDir) {
    Remove-Item -LiteralPath $packageDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $packageDir, $zipDir | Out-Null

Copy-Item -Force -LiteralPath $exe -Destination $outExe
Copy-Item -Force -LiteralPath (Join-Path $scriptDir "Start-iOS-Indexing-Checker.cmd") -Destination $packageDir
Copy-Item -Force -LiteralPath (Join-Path $scriptDir "Start-iOS-Indexing-Checker.ps1") -Destination $packageDir
Copy-Item -Force -LiteralPath $packageReadme -Destination $packageDir

Compress-Archive -Force -LiteralPath `
    (Join-Path $packageDir "Start-iOS-Indexing-Checker.cmd"), `
    (Join-Path $packageDir "Start-iOS-Indexing-Checker.ps1"), `
    (Join-Path $packageDir "IosIndexingProgress.exe"), `
    (Join-Path $packageDir "README_OneClick_Distribution.txt") `
    -DestinationPath $zip

Write-Host "Built: $outExe"
Write-Host "Package: $zip"
