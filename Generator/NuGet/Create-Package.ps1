<#
.SYNOPSIS
Creates the Swift/WinRT nuget package, including the code generator executable and support module sources.
#>
[CmdletBinding(PositionalBinding=$false)]
param(
    [string] $X64Exe = $null,
    [string] $Arm64Exe = $null,
    [string] $MscorlibWinMD = $null,
    [string] $SwiftRedistDir = $null,
    [string] $Version = "0.0.0",
    [string] $IntermediateDir = $null,
    [string] $NuGetExe = "nuget.exe",
    [Parameter(Mandatory=$true)]
    [string] $OutputPath)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue" # Faster Invoke-WebRequest

# Global constants
$WixVersion = "5.0.2"
$StagingDir = "" # Will be set later
$RepoRoot = (& git.exe -C "$PSScriptRoot" rev-parse --path-format=absolute --show-toplevel).Trim()

function FindSwiftRedistDir([string] $Hint) {
    if ($Hint) {
        if (!(Test-Path "$Hint\rtl.amd64.msm")) {
            throw "Invalid Swift redist directory: $Hint"
        }
        return $Hint
    }

    $SwiftCompilerPath = (& where.exe swiftc.exe) | Out-String
    $PathMatch = [Regex]::Match($SwiftCompilerPath, "^(?<root>.*)\\Toolchains\\(?<version>\d+\.\d+\.\d+)(\+\w+)?\\")
    $SwiftRoot = $PathMatch.Groups["root"].Value
    $SwiftVersion = $PathMatch.Groups["version"].Value
    return "$SwiftRoot\Redistributables\$SwiftVersion"
}

function DownloadWiX() {
    $ExePath = "$IntermediateDir\wix.$WixVersion\tools\net6.0\any\wix.exe"
    if (Test-Path $ExePath) { return $ExePath }

    if (!(Test-Path "$IntermediateDir\wix.$WixVersion")) {
        if (!(Test-Path "$IntermediateDir\wix.$WixVersion.nupkg")) {
            Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/wix/$WixVersion" -OutFile "$IntermediateDir\wix.$WixVersion.nupkg"
        }

        Expand-Archive -Path "$IntermediateDir\wix.$WixVersion.nupkg" -DestinationPath "$IntermediateDir\wix.$WixVersion"
    }

    return $ExePath
}

function StageSupportModule() {
    New-Item -ItemType Directory -Path "$StagingDir\swift" -Force | Out-Null
    $PackageSwift = Get-Content -Path "$RepoRoot\Package.swift" -Raw -Encoding UTF8
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

    Out-File -FilePath "$StagingDir\swift\Package.swift" -InputObject "$PackageSwift" -Encoding UTF8
    Copy-Item -Path "$RepoRoot\Package.resolved" -Destination "$StagingDir\swift\" -Force -ErrorAction Ignore | Out-Null # Might not have one
    Copy-Item -Path "$RepoRoot\Support\Sources\*" -Destination "$StagingDir\swift\" -Recurse -Force | Out-Null
}

function ExtractSwiftRuntime([string] $Arch, [string] $Msm, [string] $WixExe) {
    $DestDir = "$IntermediateDir\SwiftRuntime\$Arch"
    if (Test-Path "$DestDir\swiftCore.dll") { return $DestDir }

    $DecompileDir = "$IntermediateDir\SwiftRuntime\Msms\$Arch"
    $WixXmlPath = "$DecompileDir\wix.xml"

    if (!(Test-Path $WixXmlPath)) {
        New-Item -ItemType Directory -Path $DecompileDir -Force | Out-Null
        & $WixExe msi decompile -sct -sdet -sras -sui -type msm -x $DecompileDir -o $WixXmlPath $Msm
    }

    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null

    [Xml]$WixXml = Get-Content $WixXmlPath
    $ns = @{ns="http://wixtoolset.org/schemas/v4/wxs"}
    $FileNodes = Select-Xml -Xml $WixXml -XPath '//ns:Component/ns:File' -Namespace $ns
    foreach ($FileNode in $FileNodes) {
        $SourceFile = "$DecompileDir\" + $FileNode.Node.GetAttribute("Source").Replace("SourceDir\", "")
        $DestFile = "$DestDir\" + $FileNode.Node.GetAttribute("Name")
        Copy-Item -Path $SourceFile -Destination $DestFile -Force | Out-Null
    }

    # Remove unnecessary binaries
    Remove-Item -Path "$DestDir\*.exe" -Force | Out-Null
    Remove-Item -Path "$DestDir\FoundationNetworking.dll" -Force | Out-Null

    return $DestDir
}

function StageBinaries([string] $Arch, [string] $Exe, [string] $MscorlibWinMD, [string] $SwiftRuntimeMsm, [string] $WixExe) {
    $DestDir = "$StagingDir\tools\$Arch"

    if (!$MscorlibWinMD) {
        $MscorlibWinMD = (Split-Path $Exe) + "\mscorlib.winmd"
    }

    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    Copy-Item -Path $Exe -Destination "$DestDir\SwiftWinRT.exe" -Force | Out-Null
    Copy-Item -Path $MscorlibWinMD -Destination "$DestDir\mscorlib.winmd" -Force | Out-Null

    $SwiftRuntimeDir = & ExtractSwiftRuntime -Arch $Arch -Msm $SwiftRuntimeMsm -WixExe $WixExe
    Copy-Item -Path "$SwiftRuntimeDir\*.dll" -Destination "$DestDir\" -Force | Out-Null
}

function StagePackage() {
    $SwiftRedistDir = & FindSwiftRedistDir -Hint $SwiftRedistDir

    Write-Host "Downloading WiX..."
    $WixExe = & DownloadWiX

    Write-Host "Staging files..."
    if ($X64Exe) {
        Write-Host "  x64 binaries..."
        StageBinaries `
            -Arch "x64" `
            -Exe $X64Exe `
            -MscorlibWinMD $MscorlibWinMD `
            -SwiftRuntimeMsm "$SwiftRedistDir\rtl.amd64.msm" `
            -WixExe $WixExe
    }

    if ($Arm64Exe) {
        Write-Host "  arm64 binaries..."
        StageBinaries `
            -Arch "arm64" `
            -Exe $Arm64Exe `
            -MscorlibWinMD $MscorlibWinMD `
            -SwiftRuntimeMsm "$SwiftRedistDir\rtl.arm64.msm" `
            -WixExe $WixExe
    }

    Write-Host "  support module..."
    & StageSupportModule

    Write-Host "  json schema..."
    New-Item -ItemType Directory "$StagingDir\json" -Force | Out-Null
    Copy-Item -Path "$RepoRoot\Generator\Projection.schema.json" -Destination "$StagingDir\json\" -Force | Out-Null

    Write-Host "  readme..."
    Copy-Item -Path "$RepoRoot\Readme.md" -Destination "$StagingDir\" -Force | Out-Null
}

function CreatePackage {
    $NuGetArgs = @("pack",
        "-NonInteractive",
        "-BasePath", $StagingDir,
        "-OutputDirectory", $IntermediateDir
        "-Version", $Version,
        "$PSScriptRoot\Package.nuspec")

    & $NuGetExe @NuGetArgs | Out-Host

    return @(Get-ChildItem -Path $IntermediateDir -Filter "*.nupkg")[0].FullName
}

function Main {
    if (!$X64Exe -and !$Arm64Exe) {
        Write-Error "One executable path must be specified."
        exit 1
    }

    $OwnIntermediateDir = $false
    if (!$IntermediateDir) {
        $script:IntermediateDir = [System.IO.Path]::Combine($Env:TEMP, [Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $IntermediateDir -Force | Out-Null
        $OwnIntermediateDir = $true
    }
    else {
        $script:IntermediateDir = (Resolve-Path $IntermediateDir).Path
    }

    $StagingDir = "$IntermediateDir\Staging"
    Remove-Item -Path $StagingDir -Force -Recurse -ErrorAction Ignore | Out-Null
    New-Item -ItemType Directory -Path $StagingDir -Force | Out-Null

    try {
        StagePackage

        Write-Host "Creating NuGet package..."
        $PackageFile = CreatePackage

        Write-Host "Copying package to $OutputPath..."
        $OutputPath = (Resolve-Path $OutputPath).Path
        if ($OutputPath -ne $PackageFile) {
            Copy-Item -Path $PackageFile -Destination $OutputPath -Force | Out-Null
        }
    }
    finally {
        if ($OwnIntermediateDir) {
            Write-Host "Cleaning up staged files..."
            Remove-Item -Path $IntermediateDir -Force -Recurse | Out-Null
        }
    }
}

Main