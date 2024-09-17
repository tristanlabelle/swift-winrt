[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory = $true)]
    [string] $SwiftWinRT,
    [Parameter(Mandatory = $true)]
    [string] $WinMD,
    [string] $OutputDir = "$PSScriptRoot\Generated"
)

Set-StrictMode -Version 3
$ErrorActionPreference = "Stop"

$WindowsSDKVersion = $env:WindowsSDKVersion -replace "\\",""
& $SwiftWinRT `
    --config "$PSScriptRoot\projection.json" `
    --winsdk $WindowsSDKVersion `
    --reference $WinMD `
    --spm `
    --cmakelists `
    --support "..\.." `
    --out $OutputDir `
    --out-manifest "$OutputDir\WinRTComponent.manifest" | Write-Host
if ($LASTEXITCODE -ne 0) { throw "Failed to generate Swift projection for WinRT component" }

if ($MyInvocation.PSCommandPath) {
    # Return the path to PowerShell
    Write-Output $OutputDir
}