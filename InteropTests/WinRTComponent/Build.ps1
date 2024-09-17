[CmdletBinding(PositionalBinding = $false)]
param(
    [string] $Platform = "",
    [string] $Configuration = "Debug"
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
    -p:IntermediateOutputPath=obj\$Configuration\ `
    -p:OutputPath=bin\$Configuration\ `
    -verbosity:minimal `
    $PSScriptRoot\WinRTComponent.vcxproj
if ($LASTEXITCODE -ne 0) { throw "Failed to build WinRT component" }

Write-Output "$PSScriptRoot\bin\$MSBuildConfiguration\$Platform\WinRTComponent"