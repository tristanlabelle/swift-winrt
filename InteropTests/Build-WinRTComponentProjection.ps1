<#
.SYNOPSIS
Builds the WinRTComponent winmd, dll, and generates its Swift projection.
Supports the SPM build of this project.

.PARAMETER SwiftWinRT
The path to SwiftWinRT.exe. If not provided, the script will build it with SPM.
#>
[CmdletBinding(PositionalBinding = $false)]
param(
    [string] $SwiftWinRT
)

Set-StrictMode -Version 3
$ErrorActionPreference = "Stop"

if (-not $SwiftWinRT) {
    Write-Host -ForegroundColor Cyan "Building SwiftWinRT.exe with SPM..."
    $SwiftConfiguration = "debug"
    $GeneratorProjectDir = "$PSScriptRoot\..\Generator"
    & swift.exe build `
        --package-path $GeneratorProjectDir `
        --configuration $SwiftConfiguration `
        --build-path "$GeneratorProjectDir\.build"
    if ($LASTEXITCODE -ne 0) { throw "Failed to build SwiftWinRT.exe" }
    $SwiftWinRT = "$GeneratorProjectDir\.build\$SwiftConfiguration\SwiftWinRT.exe"
}

Write-Host -ForegroundColor Cyan "Building WinRTComponent.dll & winmd..."
$CMakePreset = "debug"
Push-Location "$PSScriptRoot\WinRTComponent"
    & cmake.exe --preset $CMakePreset
    & cmake.exe --build --preset $CMakePreset
Pop-Location
$WinRTComponentBinDir = "$PSScriptRoot\WinRTComponent\build\$CMakePreset"

Write-Host -ForegroundColor Cyan "Generating Swift projection for WinRT component..."
& cmake.exe `
    -D "SWIFTWINRT_EXE=$SwiftWinRT" `
    -D "WINRTCOMPONENT_WINMD=$WinRTComponentBinDir\WinRTComponent.winmd" `
    -D "PROJECTION_JSON=$PSScriptRoot\projection.json" `
    -D "PROJECTION_DIR=$PSScriptRoot\Generated" `
    -D "SPM_SUPPORT_MODULE_DIR=$PSScriptRoot\.." `
    -P "$PSScriptRoot\GenerateProjection.cmake"

Write-Host -ForegroundColor Cyan "Copying the WinRT component dll next to the test..."
$SwiftTestPackageDir = $PSScriptRoot
$SwiftTestBuildOutputDir = "$SwiftTestPackageDir\.build\x86_64-unknown-windows-msvc\debug\" # Tests are always built in debug mode
New-Item -ItemType Directory -Force -Path $SwiftTestBuildOutputDir | Out-Null
Copy-Item -Path $WinRTComponentBinDir\WinRTComponent.dll -Destination $SwiftTestBuildOutputDir -Force
