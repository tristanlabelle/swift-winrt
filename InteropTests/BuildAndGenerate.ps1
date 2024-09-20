[CmdletBinding(PositionalBinding = $false)]
param(
    [switch] $Release
)

Set-StrictMode -Version 3
$ErrorActionPreference = "Stop"

Write-Host -ForegroundColor Cyan "Building SwiftWinRT.exe with SPM..."
$SwiftConfiguration = if ($Release) { "release" } else { "debug" }
$GeneratorProjectDir = "$PSScriptRoot\..\Generator"
& swift.exe build `
    --package-path $GeneratorProjectDir `
    --configuration $SwiftConfiguration `
    --build-path "$GeneratorProjectDir\.build"
if ($LASTEXITCODE -ne 0) { throw "Failed to build SwiftWinRT.exe" }
$SwiftWinRT = "$GeneratorProjectDir\.build\$SwiftConfiguration\SwiftWinRT.exe"

Write-Host -ForegroundColor Cyan "Building WinRTComponent.dll & winmd..."
$CMakePreset = if ($Release) { "release" } else { "debug" }
Push-Location "$PSScriptRoot\WinRTComponent"
& cmake.exe --preset $CMakePreset
& cmake.exe --build --preset $CMakePreset
Pop-Location
$WinRTComponentBinDir = "$PSScriptRoot\WinRTComponent\build\$CMakePreset"

Write-Host -ForegroundColor Cyan "Generating Swift projection for WinRT component..."
& "$PSScriptRoot\GenerateProjection.ps1" -SwiftWinRT $SwiftWinRT -WinMD "$WinRTComponentBinDir\WinRTComponent.winmd"

Write-Host -ForegroundColor Cyan "Copying the WinRT component dll next to the test..."
$SwiftTestPackageDir = $PSScriptRoot
$SwiftTestBuildOutputDir = "$SwiftTestPackageDir\.build\x86_64-unknown-windows-msvc\$SwiftConfiguration\"
New-Item -ItemType Directory -Force -Path $SwiftTestBuildOutputDir | Out-Null
Copy-Item -Path $WinRTComponentBinDir\WinRTComponent.dll -Destination $SwiftTestBuildOutputDir -Force
