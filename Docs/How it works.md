# How it works

Swift/WinRT has three layers which build up in complexity: ABI bindings, COM bindings, and WinRT projections.

The term "binding" refers the mapping of an ABI type to a Swift type. The term "projection" refers to mapping an entire WinRT module's into Swift.

## ABI Bindings

It is a general problem when interop'ing with C code that values need to be converted between a Swift representation and an ABI representation. A simple example is between `Swift.String` and `const char*`. Swift's native C/C++ interop allows calling C functions directly, but it requires dealing with C types directly from Swift code, such as `UnsafePointer<CChar>`, which makes API usage difficult.

Swift/WinRT has a general mechanism for these bindings: the `ABIBinding` protocol. This protocol has only static members and defines:

- `associatedtypes` for the ABI and Swift type representations.
- A means to convert from the ABI representation to the Swift representation.
- A means to convert from the Swift representation and the ABI representation.
- A means to free resources owned by the ABI representation, if any.

For example, a `CStringUTF8MallocBinding` could have:

- Typealiases for `Swift.String` and  `UnsafePointer<CChar>`
- Use `String(fromCString:)` to convert from `UnsafePointer<CChar>` and `String`
- Use `malloc` and copying `String.utf8` to create an `UnsafePointer<CChar>` from a `String`
- Use `free` to release `UnsafePointer<CChar>` values

There could be multiple bindings for some Swift or ABI type representations. For example, there could be a `CStringASCIIMallocBinding` with the same types but a different implementation of the conversion and freeing functions.

## COM Bindings

COM bindings build on top of ABI bindings when the ABI representation is a COM interface.

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
extension SWRT_IFoo {
    public static let iid = COMInterfaceID(0x94EA2B94, 0xE9CC, 0x49E0, 0xC0FF, 0xEE64CA8F5B90)
}

extension COMInterop when T == SWRT_IFoo {
    func getName() throws -> String {
        var name: BSTR? = nil
        defer { BStrBinding.release(&name) }
        try COMError.fromABI(pointer.pointee.vtable.pointee.GetName(pointer, &name))
        return BStrBinding.fromABI(name)
    }
}

// Now we can do:
let name = try COMInterop(pointer).getName()
```

### COMImport Wrappers (generated)

Our `IFooBinding` will convert between `UnsafeMutablePointer<SWRT_IFoo>?` as the ABI representation and `IFoo?` as the Swift representation (allowing for null pointers), and back. Therefore, we need to generate an `IFooProtocol` implementation that will wrap an `UnsafeMutablePointer<SWRT_IFoo>`. These are the `COMImport` wrappers. In our case, it'll look like:

```swift
private class IFooImport: COMImport<IFooBinding>, IFooProtocol {
    public func getName() throws -> String {
        try _interop.getName() // _interop is a COMInterop<SWRT_IFoo> from the base class.
    }
}
```

The `COMImport` base class handles the reference counting of the underlying COM object and implements `queryInterface`. If the `IFoo` interface requires other interfaces like `IBar`, this `IFooImport` class would also provide implementations for the additional methods from `IBarProtocol`.

### COMBinding (generated)

At this point we have enough to generate our ABI binding type, which as we recall is used to map values between their ABI and Swift representations. This conceptually looks like the below:
```swift
enum IFooBinding: COMBinding { // COMBinding conforms to ABIBinding
    public typealias SwiftValue = IFoo?
    public typealias ABIValue = UnsafeMutablePointer<SWRT_IFoo>?
    
    public static var interfaceID: COMInterfaceID { SWRT_IFoo.iid }
    
    public static func fromABI(_ value: UnsafeMutablePointer<SWRT_IFoo>?) -> IFoo? {
        guard let value else { return nil }
        return IFooImport(addingRef: value)
    }

    public static func toABI(_ value: IFoo?) throws -> UnsafeMutablePointer<SWRT_IFoo>? {
        guard let value else { return nil }
        return try value._queryInterface(Self.self)
    }
}
```

### COMExport Base Class

What if we want to implement `IFooProtocol` in Swift and pass it to a COM method?

This is a different problem. Now we have a Swift native object that we must turn into a COM-compatible unsafe pointer. To do so, we use one field of the class that is designed to look like a COM object, with a virtual table pointer and an unsafe pointer back to the embedding Swift class. The virtual tables are constant and have their implementations in terms of the owning object's protocol methods.

For example:

```swift
class MyFoo: COMExport<IFooBinding>, IFooProtocol {
    public func getName() throws -> String { "George" }
}

// COMExport has a field that looks like a COM object:
// typedef struct SWRT_SwiftCOMObject {
//     const void* virtualTable;
//     void* swiftObject; // Will point back to MyFoo
// } SWRT_SwiftCOMObject;

enum IFooBinding {
    private static var virtualTable: SWRT_IFoo_VirtualTable = .init(
        QueryInterface: { IUnknownVirtualTable.QueryInterface($0, $1, $2) },
        AddRef: { IUnknownVirtualTable.AddRef($0) },
        Release: { IUnknownVirtualTable.Release($0) },
        // _implement casts "this" to SWRT_SwiftCOMObject and resolves swiftObject to an IFoo for the closure
        GetName: { this, value in _implement(this) { try $0.getName() } })
}
```

### COM Aggregation

COM also supports [aggregation](https://learn.microsoft.com/en-us/windows/win32/com/aggregation), an advanced scenario in which an object both exports a COM interface that it implements, but also delegates the implementation of other interfaces to a COM object that is implemented elsewhere.

[To be written]

## WinRT Bindings

### Primitive types

Most primitive WinRT types bind to Swift trivially: the ABI-level Int32 type maps to the Swift Int32 type, etc. Strings are a little more complicated since their ABI representation is an HSTRING which has special lifetime semantics, but we can handle these easily with the ABIBinding machinery.

### Enums

[To be written]

### Structs

[To be written]

### Interfaces

[To be written]

### Delegates

The ABI representation of delegates is similar to a single-method interface, however delegates are IUnknown compliant without being IInspectable compliant. The Swift side of the story also has complexity because closures have no notion of identity, so we lose that in the projection.

### Static classes

[To be written]

### Sealed classes

[To be written]

### Unsealed classes

[To be written]