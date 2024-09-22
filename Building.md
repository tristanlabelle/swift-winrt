# Building

This project is configured to build with both CMake and the Swift Package Manager (SPM), with caveats:

- Due to XCTest's dependency on SPM-generated code, the CMake build does not build tests.
- Due to SPM limitations, the SPM build requires support from Powershell scripts.

Pull requests are validated with a GitHub Actions workflow which builds using both build systems and runs tests from the SPM build.

## CMake

To build with CMake, open a `VS Developer Command Prompt` at the root of this repo and type:

```cmd
cmake --preset debug
cmake --build --preset debug
```

When building from the root of the repo, the Generator project will be built during the configure phase, so that the resulting executable can be used to generate test projections later in the build.

The repo is configured such that many subdirectories can be built the same way, to scope down the build.

You can also use [Visual Studio Code](https://code.visualstudio.com/) with the [CMake Tools extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cmake-tools) to configure and build, as long as you start it from within a `VS Developer Command Prompt`.

## SPM

The root of the repo is an SPM package that builds the support module and can run its tests. This allows SPM references to the git repo to resolve to the support module.

```cmd
swift build --build-tests
swift test --skip-build
```

The `/Generator` subdirectory is an independent SPM package that builds the code generator and can run its tests:

```cmd
Generator> swift build --build-tests
Generator> swift test --skip-build
```

The `/Generator/InteropTests` subdirectory requires building `WinRTComponent.winmd` and `WinRTComponent.dll`, which SPM cannot do. A helper script, `SPMPrebuild.ps1`, will do that using CMake, after which the package can be built and tested normally.
