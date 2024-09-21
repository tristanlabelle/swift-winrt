# Swift/WinRT

![Build & test workflow status](https://github.com/tristanlabelle/swift-winrt/actions/workflows/build-and-test.yml/badge.svg?branch=main)

A Swift projection for WinRT APIs, written in pure Swift, for consuming modern Windows Runtime APIs, the Windows App SDK, WinUI and arbitrary WinRT components.

Swift/WinRT includes:

- A code generator for Swift definitions of WinRT APIs described in `.winmd` files, based on the [swift-dotnetmetadata](https://github.com/tristanlabelle/swift-dotnetmetadata) project.
- Support libraries for projecting COM and WinRT types, and invoking related core platform APIs such as `RoInitialize`.

For examples of using projections, refer to [interop tests](InteropTests/Tests).

This project was inspired by its C++ namesake at [thebrowsercompany/swift-winrt](https://github.com/thebrowsercompany/swift-winrt).

## Using in your project

Note: Swift/WinRT requires Swift 5.10 or above due to uses of non-copyable types which crash the Swift 5.9 compiler.

### With CMake

Setup your project's build to:

1. Download the latest NuGet package from this repo's [Releases](https://github.com/tristanlabelle/swift-winrt/releases). Eventually those will be pushed to `nuget.org`.
2. Invoke the `SwiftWinRT.exe` located in the NuGet package, specifying:
   - The Windows SDK and WinMD files to be projected.
   - A `projection.json` file to describe the modules to generate, which assemblies should contribute to each of them, and which types to include. Refer to [this example](https://github.com/tristanlabelle/swift-winrt/blob/main/InteropTests/projection.json).
   - An output directory path.
3. Reference and build the support module under the `swift` subdirectory of the NuGet package.
4. Reference and build the generated code modules. For each module specified in `projection.json`, there should be an assembly module (with projected types), an ABI module (with C code) and any number of namespace modules (with type aliases for convenience).

### With the Swift Package Manager (SPM)

SPM cannot integrate arbitrary build steps needed for fully integrating Swift/WinRT code generation in your build. Alternatives:

- Create a pre-build script for the code generation step.
- Pregenerate your projections in a repository and reference it as a normal dependency.

When invoking `SwiftWinRT.exe`, specify to generate a `Package.swift` file that references the `swift` subdirectory of the NuGet package as the support module location, or reference it from this repository.

## Feature set

Swift/WinRT should support the majority of WinRT interop scenarios thanks to the following features:

- Swift representation of the full WinRT type system:
  - **Core types**: boolean, integers, floats, char16, string, guid, `IInspectable`
  - **Type definitions**: structs, enums, interfaces (+generic), delegates (+generic), classes (activatable, composable and static)
  - **Members (instance and static)**: constructors, struct fields, enumerants, methods, properties, events
  - **Parameters**: in, inout, out, and return values
  - **Types**: arrays, `IReference<T>` boxing, `IAsyncInfo`/`IAsyncOperation`, weak references and collection interfaces
  - **Nullability** and **exceptions**
  - **Namespaces**
- Documentation comment generation from xml documentation
- Interoperability between WinRT objects and COM interfaces
- Implementing COM or WinRT interfaces in Swift objects to be used by WinRT
- Deriving from WinRT composable classes, e.g. for Xaml controls
- Manifest and registration-less WinRT class instantiation
- Opt-in upcasting support, e.g. casting a returned WinRT `UIElement` to a `Button` using `as`

## Design philosophy

- **Correctness & completeness first**: The information loss from WinRT APIs should be minimal, including when this results in less Swifty code. For example, most methods are throwing as to capture any failure HRESULTs, and namespaces are simulated to avoid name clashes. If information loss is desirable for ergonomics, opt-in switches may be provided.

- **Readability of projections**: The generated types and projection glue code should be as readable as possible to ensure correctness and so that one can easily debug into the generated code as necessary.

- **Interoperability with COM**: It should be trivial to query WinRT objects for COM interfaces and use them as such. In fact, this project is designed to be extensible to eventually generate COM API descriptions from the [Win32 Metadata](https://github.com/microsoft/win32metadata) project or COM type libraries.

- **Composability**: It should be possible to generate projections for individual assemblies independently and have them interoperate.

- **Independence from Windows headers**: The generated code should not rely on header files from the Windows SDK, but rather produce any C definitions it requires.
