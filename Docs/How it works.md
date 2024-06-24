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

- **Importing**: We want to "import" a COM object and it from Swift. For example, using the shell `IFileOpenDialog` interface from Swift code.
- **Exporting**: We want to "export" Swift object and allow COM code to use it. For example, implementing `IServiceProvider` in Swift and passing it to COM code.

COM aggregation/composition is a special case where the two of those are happening at the same time.

The subsections below walk through the layers of generated code for a sample `IFoo` COM interface which exposes a single `GetName(BSTR*)` method.

### Swift Protocols (generated)

We use protocols with existentials (`any`) as the projected representation for COM interfaces in Swift code, since they behave similarly. We generate:

```swift
public protocol IFooProtocol: IUnknownProtocol {
    func getName() throws -> String
}
public typealias IFoo = any IFooProtocol
```

### C ABI Structs (generated)

The COM ABI represents objects as a pointer to an `IUnknown`-derived object, where the target's first piece of data is a pointer to an `IUnknown`-compliant virtual table. These must be expressed in C so that the ABI is honored by Swift during COM method calls. We generate:

```C
struct SWRT_IFoo { SWRT_IFoo_VTable* vtable; };
struct SWRT_IFoo_VTable {
    HRESULT (*QueryInterface)(SWRT_IFoo*, CLSID*, void**);
    UINT (*AddRef)(SWRT_IFoo*);
    UINT (*Release)(SWRT_IFoo*);
    HRESULT (*GetName)(SWRT_IFoo*, BSTR*);
};
```

These COM ABI structs can then be used as unsafe pointers in Swift using `UnsafeMutablePointer<SWRT_IFoo>`, although this makes reference counting manual, and method calls impractical:

```swift
var name: BSTR?
CheckHResult(pointer.pointee.vtable.pointee.GetName(pointer, &name))
// Convert BSTR to String
pointer.pointee.vtable.pointee.Release(pointer)
```

### COMInterop Helpers (generated)

To make such COM objects more usable, we use a `COMInterop<T>` struct which wraps `UnsafeMutablePointer<T>` and extends it with projected methods mapping one-to-one with the COM interface, with:

- Projected parameter types (such as `String`), and the logic to convert them to and from their ABI representation.
- HRESULTS converted to thrown errors conforming to `COMError`, which exposes the HRESULT.
- Trailing byref output parameters converted to return values..

For example:

```swift
extension COMInterop when T == SWRT_IFoo {
    func getName() throws -> String {
        var name: BSTR? = nil
        defer { BStrProjection.release(&name) }
        try HResult.throwIfFailed(pointer.pointee.vtable.pointee.GetName(pointer, &name))
        return BStrProjection.toSwift(name)
    }
}

// Now we can do:
let name = try COMInterop(pointer).getName()
```

### COMImport Wrappers (generated)

Our `IFooProjection` will convert between `UnsafeMutablePointer<SWRT_IFoo>?` as the ABI representation and `IFoo?` as the Swift representation (allowing for null pointers), and back. Therefore, we need to generate an `IFooProtocol` implementation that will wrap an `UnsafeMutablePointer<SWRT_IFoo>`. These are the `COMImport` wrappers. In our case, it'll look like:

```swift
private class IFooImport: COMImport<IFooProjection>, IFooProtocol {
    public func getName() throws -> String {
        try _interop.getName() // _interop is a COMInterop<SWRT_IFoo> from the base class.
    }
}
```

This class is private and instantiated within `IFooProjection.toSwift(pointer)`. The `COMImport` base class handles the reference counting of the underlying COM object and implements `queryInterface`.

### COMExport Base Class

What if we want to implement `IFooProtocol` in Swift and pass it to a COM method?

[To be written]

## WinRT Projections

[To be written]