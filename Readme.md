# Swift/WinRT

![Build & test workflow status](https://github.com/tristanlabelle/swift-winrt/actions/workflows/build-and-test.yml/badge.svg?branch=main)

A Swift projection for WinRT APIs, written in pure Swift, for consuming modern Windows Runtime APIs, the Windows Application SDK, WinUI and arbitrary WinRT components, or producing your own.

Swift/WinRT consists in:

- A code generator for Swift definitions of WinRT APIs described in `.winmd` files, based on the [swift-dotnetmetadata](https://github.com/tristanlabelle/swift-dotnetmetadata) project.
- Support libraries for projecting COM and WinRT types, and invoking related core platform APIs such as `RoInitialize`.

For examples of using projections, refer to [interop tests](InteropTests/Tests).

This project is a pure Swift rewrite of [its namesake from The Browser Company](https://github.com/thebrowsercompany/swift-winrt).

## Design philosophy

- **Correctness & completeness first**: The information loss from WinRT APIs should be minimal, including when this results in less Swifty code. For example, most methods are throwing as to capture any failure HRESULTs, and namespaces are simulated to avoid name clashes. If information loss is desirable for ergonomics, opt-in switches may be provided.

- **Readability of projections**: The generated types and projection glue code should be as readable as possible to ensure correctness and so that one can easily debug into the generated code as necessary.

- **Interoperability with COM**: It should be trivial to query WinRT objects for COM interfaces and use them as such. In fact, this project is designed to be extensible to eventually generate COM API descriptions from the [Win32 Metadata](https://github.com/microsoft/win32metadata) project or COM type libraries.

- **Composability**: It should be possible to generate projections for individual assemblies independently and have them interoperate.

- **Independence from Windows headers**: The generated code should not rely on header files from the Windows SDK, but rather produce any C definitions it requires.
