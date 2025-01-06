<#
.SYNOPSIS
Builds mscorlib.winmd and locates it next to SwiftWinRT.exe.

.PARAMETER Config
The build configuration that was used to build SwiftWinRT.exe.
#>
[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory = $true)]
    [string] $Config
)

$TargetTripleArch = switch ($Env:PROCESSOR_ARCHITECTURE) {
    "amd64" { "x86_64" }
    "arm64" { "aarch64" }
    "x86" { "i686" }
    default { throw "Unsupported architecture: $Env:PROCESSOR_ARCHITECTURE" }
}

$BinaryDir = "$PSScriptRoot\.build\$TargetTripleArch-unknown-windows-msvc\$Config"
if (-not (Test-Path $BinaryDir)) {
    throw "The binary directory does not exist: $BinaryDir"
}

& "$PSScriptRoot\.build\checkouts\swift-dotnetmetadata\WindowsMetadataCoreLibrary\Assemble.ps1" -OutputPath "$BinaryDir\mscorlib.winmd"