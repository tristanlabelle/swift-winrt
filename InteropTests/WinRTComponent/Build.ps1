[CmdletBinding(PositionalBinding = $false)]
param(
    [string] $Platform = "",
    [string] $Configuration = "Debug",
    [string] $BinaryDirBase = $PSScriptRoot
)

Set-StrictMode -Version 3
$ErrorActionPreference = "Stop"

switch ($Env:PROCESSOR_ARCHITECTURE) {
    "ARM64" { $Platform = "arm64" }
    "AMD64" { $Platform = "x64" }
    "x86" { $Platform = "x86" }
    default { throw "Unsupported architecture: $($Env:PROCESSOR_ARCHITECTURE)" }
}

& msbuild.exe -restore `
    -p:RestorePackagesConfig=true `
    -p:Platform=$Platform `
    -p:Configuration=$Configuration `
    -p:IntermediateOutputPath=$BinaryDirBase\obj\$Configuration\ `
    -p:OutputPath=$BinaryDirBase\bin\$Configuration\ `
    -verbosity:minimal `
    $PSScriptRoot\WinRTComponent.vcxproj | Write-Host
if ($LASTEXITCODE -ne 0) { throw "Failed to build WinRT component" }

Write-Output "$BinaryDirBase\bin\$Configuration\$Platform\WinRTComponent"