[CmdletBinding(PositionalBinding=$false)]
param(
    [Parameter(Mandatory=$true)]
    [string] $In,
    [Parameter(Mandatory=$true)]
    [string] $Out
)

$ErrorActionPreference = "Stop"

$PEBytes = [IO.File]::ReadAllBytes($In)
$MSDosSignature = [BitConverter]::ToUInt16($PEBytes, 0x0)
if ($MSDosSignature -ne 0x5A4D) { throw "Invalid MS-DOS signature" } # "MZ", little endian
$PEHeaderOffset = [BitConverter]::ToInt32($PEBytes, 0x3C)
$PESignature = [BitConverter]::ToInt32($PEBytes, $PEHeaderOffset)
if ($PESignature -ne 0x4550) { throw "Invalid PE signature" } # "PE\0\0", little endian
$PETimeDateStampOffset = $PEHeaderOffset + 0x8
[Array]::Clear($PEBytes, $PETimeDateStampOffset, 0x4)
[IO.File]::WriteAllBytes($Out, $PEBytes)