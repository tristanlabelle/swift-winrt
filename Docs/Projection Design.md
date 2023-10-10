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

### No inheritance between projection types
`IInspectableProjection` does not inherit from `IUnknownProjection`, they are both leaf types. However, `IInspectableProtocol` does require `IUnknownProjection`.

**Rationale**: Inheritance between projection types would make it impossible to conform to `COMProjection` differently between a base and derived projection class (conformance cannot be overriden), and it does not correctly express the COM ABI.

### IFoo and IFooProtocol naming
Swift protocols generated for COM/WinRT interfaces have a "Protocol" suffix. The unsuffixed interface name is used for its existential typealias.

**Rationale**: We only need to refer to Swift protocols when implementing COM interfaces from Swift, whereas existential protocols appear everywhere in signatures. This also keeps signatures very similar to C#.

**Example**: `typedef IClosable = any IClosableProtocol`

**Example**: `class CustomVector: IVectorProtocol { func getView() throws -> IVectorView }`

## Members
### Property setters as functions
Property setters are exposed as functions taking a new value argument and returning `Void`, instead of as property setters.

**Rationale**: Swift does not support throwing property setters, and we don't want to ignore or failfast on exceptions. WinRT should not overload properties to methods whereas Swift can, so this is safe.

**Example**:
```swift 
// In IAsyncAction
var completed: AsyncActionCompletedHandler { get throws }
func completed(_ value: AsyncActionCompletedHandler!) throws
```

### Nullability via thrown errors
`null` return values from WinRT methods and properties of reference types are surfaced by throwing a `NullResult` error instead of marking the Swift type as optional.

**Rationale**: Null return values are rare and WinRT projections already require handling exceptions so this unifies error handling.

**Example**: `IVector` has `func getView() throws -> IVectorView` (not nullable)

## Open Questions
### Should IFoo = any IFooProtocol?
There are two ways to project interfaces:
```swift
// IFoo = any IFooProtocol
protocol IFooProtocol: IUnknownProtocol {}
typealias IFoo = any IFooProtocol
class IFooProjection: IFoo {}
// IFoo = projection
protocol IFooProtocol {} // No need for IUnknownProtocol
class IFoo: IFooProtocol {}
```

Comparison:
| IFoo =             | any Protocol                                                 | Projection                                                   |
| ------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Typical usage      | ➕ Like C#                                                    | ➕ Like C#                                                    |
| Swift impls        | ➕ Straightforward declaration<br />➖ Straightforward passing in<br />➖ Ill-defined QI method | ➕ Straightforward declaration<br />➖ Passing in requires `.projection`<br />➕ No QI method |
| Casting ergonomics | ➕ `as` supported in most cases (⚠️)<br />➖ QI requires using `Projection` class | ➖ `as` mostly unsupported (⚠️)<br />➕ No separate `Projection` type |
| Correctness        | ➖ Can pass in non-projectable Swift objects                  | ➕ Can only pass in COM-projectable objects                   |
| Performance        | ➖ runtimeclass lookup on creation to support `as`<br />➖ Existential protocol dispatch | ➕ No runtimeclass lookup on creation (?) <br />➕ Class virtual dispatch |
