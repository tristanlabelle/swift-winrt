param(
    [switch] $Release
)

Set-StrictMode -Version 3
$ErrorActionPreference = "Stop"

$SwiftConfiguration = if ($Release) { "release" } else { "debug" }

$OriginalPathExt = $env:PATHEXT
$env:PATHEXT += ";.xctest"
& $PSScriptRoot\.build\$SwiftConfiguration\InteropTestsPackageTests.xctest
$env:PATHEXT = $OriginalPathExt