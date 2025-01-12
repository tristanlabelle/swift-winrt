<#
.SYNOPSIS
Builds the WinRTComponent winmd, dll, and generates its Swift projection.
Supports the SPM build of this project.

.PARAMETER SwiftWinRT
The path to SwiftWinRT.exe. If not provided, the script will build it with SPM.
#>
[CmdletBinding(PositionalBinding = $false)]
param(
    [string] $SwiftWinRT,
    [ValidateSet("true", "false", "null")]
    [string] $SwiftBug72724 = $null
)

Set-StrictMode -Version 3
$ErrorActionPreference = "Stop"

if (-not $SwiftWinRT) {
    Write-Host -ForegroundColor Cyan "Building SwiftWinRT.exe with SPM..."
    $BuildConfig = "debug"
    $RepoRoot = (& git.exe -C "$PSScriptRoot" rev-parse --path-format=absolute --show-toplevel).Trim()
    $GeneratorProjectDir = "$RepoRoot\Generator"

    & swift.exe build `
        --package-path $GeneratorProjectDir `
        --configuration $BuildConfig `
        --build-path "$GeneratorProjectDir\.build"
    if ($LASTEXITCODE -ne 0) { throw "Failed to build SwiftWinRT.exe" }

    & "$GeneratorProjectDir\SPMPostBuild.ps1" -Config $BuildConfig

    $TargetTripleArch = switch ($Env:PROCESSOR_ARCHITECTURE) {
        "amd64" { "x86_64" }
        "arm64" { "aarch64" }
        "x86" { "i686" }
        default { throw "Unsupported architecture: $Env:PROCESSOR_ARCHITECTURE" }
    }

    $SwiftWinRT = "$GeneratorProjectDir\.build\$TargetTripleArch-unknown-windows-msvc\$BuildConfig\SwiftWinRT.exe"
}
else {
    $SwiftWinRT = [IO.Path]::GetFullPath($SwiftWinRT)
}

Write-Host -ForegroundColor Cyan "Building WinRTComponent.dll, winmd and projection..."
Push-Location "$PSScriptRoot\WinRTComponent"
$CMakePreset = "debug" # Tests are always built in debug mode
$Defines = @(
    "-D", "SWIFTWINRT_EXE=$SwiftWinRT",
    "-D", "PROJECTION_DIR=$(Get-Location)\Projection"
)
switch ($SwiftBug72724) {
    "true" { $Defines += @("-D", "SWIFT_BUG_72724=ON") }
    "false" { $Defines += @("-D", "SWIFT_BUG_72724=OFF") }
    default {}
}
& cmake.exe --preset $CMakePreset @Defines
& cmake.exe --build --preset $CMakePreset --target WinRTComponentDll
$WinRTComponentBinDir = "$(Get-Location)\build\$CMakePreset\Dll"
Pop-Location

Write-Host -ForegroundColor Cyan "Copying the WinRT component dll next to the test..."
$SwiftTestPackageDir = $PSScriptRoot
$SwiftTestBuildOutputDir = "$SwiftTestPackageDir\.build\x86_64-unknown-windows-msvc\debug\" # Tests are always built in debug mode
New-Item -ItemType Directory -Force -Path $SwiftTestBuildOutputDir | Out-Null
Copy-Item -Path $WinRTComponentBinDir\WinRTComponent.dll -Destination $SwiftTestBuildOutputDir -Force
