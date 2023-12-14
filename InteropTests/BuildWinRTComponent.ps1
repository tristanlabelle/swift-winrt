param(
    [switch] $Release
)

Set-StrictMode -Version 3
$ErrorActionPreference = "Stop"

$SwiftConfiguration = if ($Release) { "release" } else { "debug" }
$MSBuildConfiguration = if ($Release) { "Release" } else { "Debug" }

Write-Host -ForegroundColor Cyan "Building SwiftWinRT.exe..."
$GeneratorProjectDir = "$PSScriptRoot\..\Generator"
& swift.exe build `
    --package-path $GeneratorProjectDir `
    --configuration $SwiftConfiguration `
    --build-path "$GeneratorProjectDir\.build"
if ($LASTEXITCODE -ne 0) { throw "Failed to build SwiftWinRT.exe" }
$SwiftWinRT = "$GeneratorProjectDir\.build\$SwiftConfiguration\SwiftWinRT.exe"

Write-Host -ForegroundColor Cyan "Building WinRT component..."
$TestComponentProjectDir = "$PSScriptRoot\WinRTComponent"
& msbuild.exe -restore `
    -p:RestorePackagesConfig=true `
    -p:Platform=x64 `
    -p:Configuration=$MSBuildConfiguration `
    -p:IntermediateOutputPath=obj\$MSBuildConfiguration\ `
    -p:OutputPath=bin\$MSBuildConfiguration\ `
    -verbosity:minimal `
    $TestComponentProjectDir\WinRTComponent.vcxproj
if ($LASTEXITCODE -ne 0) { throw "Failed to build WinRT component" }
$TestComponentDir = "$TestComponentProjectDir\bin\$MSBuildConfiguration\x64\WinRTComponent"

Write-Host -ForegroundColor Cyan "Generating Swift projection for WinRT component..."
& $SwiftWinRT `
    --config "$PSScriptRoot\projection.json" `
    --reference "$env:WindowsSdkDir\References\${env:WindowsSDKVersion}Windows.Foundation.FoundationContract\4.0.0.0\Windows.Foundation.FoundationContract.winmd" `
    --reference "$TestComponentDir\WinRTComponent.winmd" `
    --out "$PSScriptRoot\Generated"
if ($LASTEXITCODE -ne 0) { throw "Failed to generate Swift projection for WinRT component" }

Write-Host -ForegroundColor Cyan "Copying Package.swift for the generated code..."
Copy-Item -Path "$PSScriptRoot\GeneratedPackage.swift" -Destination "$PSScriptRoot\Generated\Package.swift" -Force

Write-Host -ForegroundColor Cyan "Copying the WinRT component dll next to the test..."
$SwiftTestPackageDir = $PSScriptRoot
$SwiftTestBuildOutputDir = "$SwiftTestPackageDir\.build\x86_64-unknown-windows-msvc\$SwiftConfiguration\"
Copy-Item -Path $TestComponentDir\WinRTComponent.dll -Destination $SwiftTestBuildOutputDir -Force
