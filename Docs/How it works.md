# How it works

Swift/WinRT has three layers which build up in complexity: ABI projections, COM projections, and WinRT projections.

The term "projection" refers to lifting ABI concepts into language-specific concepts.

## ABI Projections

It is a general problem when interop'ing with C code that values need to be converted between a Swift representation and an ABI representation. A simple example is between `Swift.String` and `const char*`. Swift's native C/C++ interop allows calling C functions directly, but it requires dealing with C types directly from Swift code, such as `UnsafePointer<CChar>`, which makes API usage difficult.

Swift/WinRT has a general mechanism for these projections: the `ABIProjection` protocol. This protocol has only static members and defines:

- `associatedtypes` for the ABI and Swift type representations.
- A means to convert from the ABI representation to the Swift representation.
- A means to convert from the Swift representation and the ABI representation.
- A means to free resources owned by the ABI representation, if any.

For example, a `CStringUTF8MallocProjection` could have:

- Typealiases for `Swift.String` and  `UnsafePointer<CChar>`
- Use `String(fromCString:)` to convert from `UnsafePointer<CChar>` and `String`
- Use `malloc` and copying `String.utf8` to create an `UnsafePointer<CChar>` from a `String`
- Use `free` to release `UnsafePointer<CChar>` values

There could be multiple projections for some Swift or ABI type representations. For example, there could be a `CStringASCIIMallocProjection` with the same types but a different implementation of the conversion and freeing functions.

## COM Projections

COM projections build on top of ABI projections when the ABI representation is a COM interface.

There are two things we may want to do with a COM interface in Swift:

- **Importing**: We want to "import" a COM object and it from Swift.
- **Exporting**: We want to "export" Swift object and allow COM code to use it.

COM aggregation/composition is a special case where the two of those are happening at the same time.

[To be continued]

## WinRT Projections

[To be written]