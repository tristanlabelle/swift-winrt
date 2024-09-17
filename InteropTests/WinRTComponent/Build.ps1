[CmdletBinding(PositionalBinding = $false)]
param(
    [string] $Platform = "",
    [string] $Configuration = "Debug",
    [string] $BinaryDirBase = ""
)

Set-StrictMode -Version 3
$ErrorActionPreference = "Stop"

switch ($Env:PROCESSOR_ARCHITECTURE) {
    "ARM64" { $Platform = "arm64" }
    "AMD64" { $Platform = "x64" }
    "x86" { $Platform = "x86" }
    default { throw "Unsupported architecture: $($Env:PROCESSOR_ARCHITECTURE)" }
}

if ($BinaryDirBase) {
    $IntermediateOutputPath = "$BinaryDirBase\obj\"
    $OutDir = "$BinaryDirBase\bin\"
}
else {
    $IntermediateOutputPath = "$PSScriptRoot\obj\$Configuration\$Platform\"
    $OutDir = "$PSScriptRoot\bin\$Configuration\$Platform\"
}

& msbuild.exe -restore `
    -p:RestorePackagesConfig=true `
    -p:Platform=$Platform `
    -p:Configuration=$Configuration `
    -p:IntermediateOutputPath=$IntermediateOutputPath `
    -p:OutDir=$OutDir `
    -verbosity:minimal `
    $PSScriptRoot\WinRTComponent.vcxproj | Write-Host
if ($LASTEXITCODE -ne 0) { throw "Failed to build WinRT component" }

if ($MyInvocation.PSCommandPath) {
    # Return the path to PowerShell
    Write-Output "$OutDir\WinRTComponent"
}