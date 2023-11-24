param(
    [switch] $Release
)

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
    -p:Configuration=$MSBuildConfiguration `
    -p:IntermediateOutputPath=obj\$MSBuildConfiguration\ `
    -p:OutputPath=bin\$MSBuildConfiguration\ `
    -verbosity:minimal `
    $TestComponentProjectDir\WinRTComponent.vcxproj
if ($LASTEXITCODE -ne 0) { throw "Failed to build WinRT component" }
$TestComponentDir = "$TestComponentProjectDir\$MSBuildConfiguration\WinRTComponent"

Write-Host -ForegroundColor Cyan "Generating Swift projection for WinRT component..."
& $SwiftWinRT `
    --config "$PSScriptRoot\projection.json" `
    --reference "$env:WindowsSdkDir\References\${env:WindowsSDKVersion}Windows.Foundation.FoundationContract\4.0.0.0\Windows.Foundation.FoundationContract.winmd" `
    --reference "$TestComponentDir\WinRTComponent.winmd" `
    --out "$PSScriptRoot\Generated"
if ($LASTEXITCODE -ne 0) { throw "Failed to generate Swift projection for WinRT component" }
