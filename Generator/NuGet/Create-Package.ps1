<#
.SYNOPSIS
Creates the Swift/WinRT nuget package, including the code generator executable and support module sources.
#>
[CmdletBinding(PositionalBinding=$false)]
param(
    [string] $NativeExe = $null,
    [string] $X64BinPath = $null,
    [string] $Arm64BinPath = $null,
    [string] $MscorlibPath = $null,
    [string] $Version = $null,
    [string] $StagingDir = $null,
    [string] $NuGetExe = "nuget.exe",
    [Parameter(Mandatory=$true)]
    [string] $OutputPath)

$ErrorActionPreference = "Stop"

if (!$NativeExe -and !$X64BinPath -and !$Arm64BinPath) {
    Write-Error "One executable or binaries path must be specified."
    exit 1
}
elseif ([bool]$NativeExe -eq ($X64BinPath -or $Arm64BinPath)) {
    Write-Error "The NativeExe and [X64|Arm64]BinPath parameters are mutually exclusive."
    exit 1
}

$OwnStagingDir = $false
if (!$StagingDir) {
    $StagingDir = [System.IO.Path]::Combine($Env:TEMP, [Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $StagingDir -Force | Out-Null
    $OwnStagingDir = $true
}

Write-Host "Staging files to $StagingDir..."
function StageMscorlib([string] $TargetDir) {
    if (!$MscorlibPath) {
        return
    }

    Write-Host "  mscorlib..."
    Copy-Item -Path $MscorlibPath -Destination $TargetDir -Force | Out-Null
}

if ($NativeExe) {
    Write-Host "  native executable..."
    $Arch = $Env:PROCESSOR_ARCHITECTURE
    if ($Arch -eq "AMD64") { $Arch = "x64" }
    New-Item -ItemType Directory -Path $StagingDir\tools\$Arch -Force | Out-Null
    Copy-Item -Path $NativeExe -Destination $StagingDir\tools\$Arch\ -Force | Out-Null

    Write-Host "  native Swift runtime..."
    $SwiftCompilerPath = (& where.exe swiftc.exe) | Out-String
    $PathMatch = [Regex]::Match($SwiftCompilerPath, "^(?<root>.*)\\Toolchains\\(?<version>\d+\.\d+\.\d+)(\+\w+)?\\")
    $SwiftRoot = $PathMatch.Groups["root"].Value
    $SwiftVersion = $PathMatch.Groups["version"].Value
    $SwiftRuntimeDir = "$SwiftRoot\Runtimes\$SwiftVersion\usr\bin"
    Copy-Item -Path $SwiftRuntimeDir\*.dll -Destination $StagingDir\tools\$Arch\ -Force | Out-Null

    StageMscorlib "$StagingDir\tools\$Arch\"
}

if ($X64BinPath) {
    Write-Host "  x64 binaries..."
    New-Item -ItemType Directory -Path $StagingDir\tools\x64 -Force | Out-Null
    Copy-Item -Path $X64BinPath -Destination $StagingDir\tools\x64\ -Recurse -Force | Out-Null
    StageMscorlib "$StagingDir\tools\x64\"
}

if ($Arm64BinPath) {
    Write-Host "  arm64 binaries..."
    New-Item -ItemType Directory -Path $StagingDir\tools\arm64 -Force | Out-Null
    Copy-Item -Path $Arm64BinPath -Destination $StagingDir\tools\arm64\ -Recurse -Force | Out-Null
    StageMscorlib "$StagingDir\tools\arm64\"
}

Write-Host "  support module sources..."
New-Item -ItemType Directory -Path $StagingDir\swift -Force | Out-Null
$RepoRoot = (& git.exe -C "$PSScriptRoot" rev-parse --path-format=absolute --show-toplevel).Trim()
$PackageSwift = Get-Content -Path $RepoRoot\Package.swift -Raw -Encoding UTF8
$PackageSwift = $PackageSwift -replace "Support/Sources/", "" # Flatten directory structure
# Remove test targets
$PackageSwift = [Regex]::Replace($PackageSwift, "
    # Match the first line of a test target
    ^(?<indentation>[ ]+)
        \.testTarget\(
        .*\n
    # Match subsequent lines of the test target (further indented)
    (
        \k<indentation> .*\n
    )*
    ", "", "CultureInvariant,ExplicitCapture,IgnorePatternWhitespace,Multiline")
Out-File -FilePath $StagingDir\swift\Package.swift -InputObject $PackageSwift -Encoding UTF8
Copy-Item -Path $RepoRoot\Package.resolved -Destination $StagingDir\swift\ -Force -ErrorAction Ignore | Out-Null # Might not have one
Copy-Item -Path $RepoRoot\Support\Sources\* -Destination $StagingDir\swift\ -Recurse -Force | Out-Null

Write-Host "  json schema..."
New-Item -ItemType Directory $StagingDir\json -Force | Out-Null
Copy-Item -Path $PSScriptRoot\..\Projection.schema.json -Destination $StagingDir\json\ -Force | Out-Null

Write-Host "  readme..."
Copy-Item -Path $RepoRoot\Readme.md -Destination $StagingDir\ -Force | Out-Null

Write-Host "Creating NuGet package..."
$NuGetArgs = @("pack",
    "-NonInteractive",
    "-BasePath", $StagingDir,
    "-OutputDirectory", $StagingDir)
if ($Version) {
    $NuGetArgs += @("-Version", $Version)
}
$NuGetArgs += @("$PSScriptRoot\Package.nuspec")

& $NuGetExe @NuGetArgs

Write-Host "Copying package to $OutputPath..."
$StagedPackagePath = @(Get-ChildItem -Path $StagingDir -Filter "*.nupkg")[0].FullName
Copy-Item -Path $StagedPackagePath -Destination $OutputPath -Force | Out-Null

if ($OwnStagingDir) {
    Write-Host "Cleaning up staged files..."
    Remove-Item -Path $StagingDir -Force -Recurse | Out-Null
}