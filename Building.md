# Building

This project is configured to build with both CMake and the Swift Package Manager (SPM), with caveats:

- Due to XCTest's dependency on SPM-generated code, the CMake build does not build tests.
- Due to SPM limitations, the SPM build requires support from Powershell scripts.

Pull requests are validated with a GitHub Actions workflow which builds using both build systems and runs tests from the SPM build.

## Prerequisites

- Windows 10 or above (building on other platforms should be possible but is untested)
- A Swift toolchain, version 5.10 or above
  - `winget install --id Swift.Toolchain`
- Visual Studio (any edition) with the Desktop C++ Workload
  - `winget install --id Microsoft.VisualStudio.2022.Community --override "--quiet --add Microsoft.VisualStudio.Workload.NativeDesktop"`
- A Windows SDK (any reasonably recent version)
  - Comes with Visual Studio, or use `winget install --id Microsoft.WindowsSDK.10.0.22000`
- CMake and ninja
  - Comes with Visual Studio, or use `winget install --id Kitware.CMake` and `winget install --id Ninja-build.Ninja`
- NuGet
  - `winget install Microsoft.NuGet`

## In Visual Studio Code
Open Visual Studio Code from a `x64 Native Tools Command Prompt for VS 2022` and use standard IDE commands for building (<kbd>ctrl</kbd>+<kbd>shift</kbd>+<kbd>B</kbd>). Subfolders `Generator` and `InteropTests` can also be opened for a scoped down development environment.

## From the command line
1. Open a `x64 Native Tools Command Prompt for VS 2022`.
2. Refer to the [Build and Test workflow](.github/workflows/build-and-test.yml) for build commands.
  - With CMake, the Generator project will be built during the configure phase so that the resulting executable can be used to generate test projections later on, but the tests themselves will not be built due to XCTest dependencies on SPM.
  - With SPM, the build is split in several steps:
    - The root `Package.swift`, which defines modules supporting the generated code.
    - The `Generator` subfolder, which builds the code genreator.
    - The `InteropTests` subfolder, which builds tests against a WinRT component and relies on a prebuild Powershell script.
