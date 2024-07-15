param(
    [string]$NativeExe = $null,
    [string]$X64BinPath = $null,
    [string]$Arm64BinPath = $null,
    [string]$Version = $null,
    [string]$StagingDir = $null,
    [string]$NuGetExe = "nuget.exe",
    [Parameter(Mandatory=$true)]
    [string]$OutputPath)

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
if ($NativeExe) {
    Write-Host "  native executable..."
    $Arch = $Env:PROCESSOR_ARCHITECTURE
    if ($Arch -eq "AMD64") { $Arch = "x64" }
    New-Item -ItemType Directory -Path $StagingDir\tools\$Arch -Force | Out-Null
    Copy-Item -Path $NativeExe -Destination $StagingDir\tools\$Arch\ -Force | Out-Null

    Write-Host "  native Swift runtime..."
    $SwiftCoreDll = (& where.exe swiftCore.dll) | Out-String
    $SwiftRuntimeDir = Split-Path $SwiftCoreDll -Parent
    Copy-Item -Path $SwiftRuntimeDir\*.dll -Destination $StagingDir\tools\$Arch\ -Force | Out-Null
}

if ($X64BinPath) {
    Write-Host "  x64 binaries..."
    New-Item -ItemType Directory -Path $StagingDir\tools\x64 -Force | Out-Null
    Copy-Item -Path $X64BinPath -Destination $StagingDir\tools\x64\ -Recurse -Force | Out-Null
}

if ($Arm64BinPath) {
    Write-Host "  arm64 binaries..."
    New-Item -ItemType Directory -Path $StagingDir\tools\arm64 -Force | Out-Null
    Copy-Item -Path $Arm64BinPath -Destination $StagingDir\tools\arm64\ -Recurse -Force | Out-Null
}

Write-Host "  support module sources..."
New-Item -ItemType Directory -Path $StagingDir\swift -Force | Out-Null
Copy-Item -Path $PSScriptRoot\..\Package.swift -Destination $StagingDir\swift\ -Force | Out-Null
Copy-Item -Path $PSScriptRoot\..\Package.resolved -Destination $StagingDir\swift\ -Force -ErrorAction Ignore | Out-Null # Might not have one
Copy-Item -Path $PSScriptRoot\..\Support -Destination $StagingDir\swift\Support\ -Recurse -Force | Out-Null

Write-Host "  readme..."
Copy-Item -Path $PSScriptRoot\..\Readme.md -Destination $StagingDir\ -Force | Out-Null

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