# Projection Design

Documents the design decisions that lead to the code shape used by Swift/WinRT projections.

## Modules and Namespaces
### Assembly to module mapping
Each assembly (or group of assemblies) is mapped to a Swift module.

**Rationale**: Assemblies can have cyclical dependencies between internal types and form a DAG of dependencies between one another, which maps to how dependencies are handled in Swift modules.

**Example**: The `Windows.winmd` union metadata assembly could map to a single UWP module.

### Qualified type names
Swift types include a namespace prefix.

**Rationale**: Type names in assemblies are only unique when fully qualified by their namespace. For example, `Windows.winmd` has 15 non-unique short type names, including `AnimationDirection` under both `Windows.UI.Composition` and `Windows.UI.Xaml.Controls`, and `Panel` under both `Windows.Devices.Enumeration` and `Windows.UI.Xaml.Controls`.

**Example**: `WindowsUIComposition_AnimationDirection` and `WindowsUIXamlControls_AnimationDirection`

### Namespace modules
One Swift module is declared for each namespace of an assembly module to provide typealias shorthands. Protocols cannot be typealiased so shorthand protocols are defined as conforming to the original qualified name protocol.

**Rationale**: Importing those modules mimics "using namespace" declarations in C#, makes type names shorter, makes dependencies clearer, and allows for disambiguation using module name qualification.

**Example**: 
```swift
// In UWP_Assembly module
public struct WindowsFoundation_AsyncStatus { /* ... */ }
public protocol WindowsFoundation_IClosableProtocol { /* .. */ }

// In UWP_WindowsFoundation module
import UWP_Assembly
public typealias AsyncStatus = WindowsFoundation_AsyncStatus
public protocol IClosableProtocol: WindowsFoundation_IClosableProtocol {}

// In app module
import UWP_WindowsFoundation
class MyClosable: IClosableProtocol {
    var status: AsyncStatus = .started
}
```

## Types
### Enums as structs
WinRT enums are projected as `Hashable` structs wrapping an Int32 value, instead of as enums. These structs implement `OptionSet` if the underlying enum has the `[Flags]` attribute.

**Rationale**: WinRT does not enforce that instances of enum types have a value that matches one of the enumerants.

**Example**:
```swift
public struct AsyncStatus: Hashable {
    public var value: Int32
    public init(_ value: Int32 = 0) { self.value = value }

    public static let started = Self(0)
    public static let completed = Self(1)
    public static let canceled = Self(2)
    public static let error = Self(3)
}
```

### No inheritance between binding types
`IInspectableBinding` does not inherit from `IUnknownBinding`, they are both leaf types. However, `IInspectableProtocol` does require `IUnknownBinding`.

**Rationale**: Inheritance between binding types would make it impossible to conform to `COMBinding` differently between a base and derived binding class (conformance cannot be overriden), and it does not correctly express the COM ABI.

### IFoo and IFooProtocol naming
Swift protocols generated for COM/WinRT interfaces have a "Protocol" suffix. The unsuffixed interface name is used for its existential typealias.

**Rationale**: We only need to refer to Swift protocols when implementing COM interfaces from Swift, whereas existential protocols appear everywhere in signatures. This also keeps signatures very similar to C#.

**Example**: `typedef IClosable = any IClosableProtocol`

**Example**: `class CustomVector: IVectorProtocol { func getView() throws -> IVectorView }`

### Upcasting support
Given a `getObject() -> Base` that actually returns a `Derived`, there is opt-in support for casting `Base` to `Derived` through implementing `SwiftObjectWrapperFactory`.

**Rationale**: The C# projection supports this and it makes for a more natural use of projections, however it requires costly dynamic wrapper type lookup and instantiation on every method return. A built-in implementation would require lower-level assemblies to know about module names of higher-level assemblies.

## Members
### Properties and accessors
Properties are generated as both throwing accessors methods and nonthrowing properties (returning implicitly unwrapped optionals).

**Rationale**: Swift does not support throwing property setters. This is a compromise between exposing errors from property accessors and supporting the convenient property syntax.

**Example**:
```swift 
func _myProperty() throws -> IClosable // Getter
func _myProperty(_ value: IClosable) throws // Setter

extension {
    var myProperty: IClosable! { get set } // Nonthrowing property
}
```

### Nullability via thrown errors
`null` return values from WinRT methods and properties of reference types are surfaced by throwing a `NullResult` error instead of marking the Swift type as optional.

**Rationale**: Null return values are rare and WinRT projections already require handling exceptions so this unifies error handling.

**Example**: `IVector` has `func getView() throws -> IVectorView` (not nullable)
