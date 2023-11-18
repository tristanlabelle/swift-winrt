param(
    [switch] $Release
)

$SwiftConfiguration = if ($Release) { "release" } else { "debug" }
$MSBuildConfiguration = if ($Release) { "Release" } else { "Debug" }

# Build the code generator
& swift.exe build --package-path Generator --configuration $SwiftConfiguration

# Build the test component (winmd file)
& msbuild.exe -restore `
    -p:RestorePackagesConfig=true `
    -p:Configuration=$MSBuildConfiguration `
    -p:IntermediateOutputPath=obj\$MSBuildConfiguration\ `
    -p:OutputPath=bin\$MSBuildConfiguration\ `
    -verbosity:minimal `
    Tests\TestComponent\TestComponent.vcxproj

# Run the code generator
& Generator\.build\debug\SwiftWinRT.exe `
    --module-map "$PSScriptRoot\Tests\modulemap.json" `
    --abi-module "CTestComponent" `
    --reference "$env:SystemRoot\System32\WinMetadata\Windows.Foundation.winmd" `
    --reference "$PSScriptRoot\Tests\TestComponent\bin\Debug\SwiftWinRT.exe" `
    --out "$PSScriptRoot\Tests\Generated"