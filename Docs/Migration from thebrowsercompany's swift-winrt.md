# Migration from thebrowsercompany/swift-winrt

This document compares [thebrowsercompany/swift-winrt](https://github.com/thebrowsercompany/swift-winrt), referred to as `v1`, to [tristanlabelle/swift-winrt](https://github.com/tristanlabelle/swift-winrt), referred to as `v2`, from a perspective of migrating from `v1` to `v2`.

## Breaking projection differences

### Interface type names

**v1**: `typealias AnyIFoo = any IFoo`

**v2**: `typealias IFoo = any IFooProtocol`

**Migration path (easy)**: Replace in files.

### Type namespacing

**v1**: None. Uses short type names without handling name clashes (e.g. )

**v2**: `NameSpace_ShortName` and namespace modules

**Migration path (easy)**: Application can define an umbrella `UWP_All` module which reexports short names for all the namespace modules that it needs, such as `UWP_MicrosoftUIXaml`.

### Null return values

**v1**: Implicitly unwrapped optionals

**v2**: throw-on-null, handled using `NullResult.catch(expr)`

**Migration path (easy)**: Fix any build errors with new code shape (resulting from `nil` comparisons or assignment to optional values)

### System.Object  type projection

**v1**: `Any`

**v2**: `IInspectable`

**Migration path (medium)**: Fix arguments to box explicitly, fix return values to unbox explicitly. 

### Support module

**v1**: Generated in lowest-level module (generally `WindowsFoundation` or `UWP`)

**v2**: Code distributed with NuGet package, or as GitHub repo reference.

**Migration path (easy)**: Change build rules to build support module.

### Support for type upcast with "as"

E.g. when `getBase()` returns `IBase` and the application code wants to convert it to `IDerived`.

**v1**: Built-in

**v2**: Optional. Pluggable.

**Migration path (medium)**: Provide `swiftWrapperFactory` implementation.

### Constructor error handling

**v1**: None. Implicit `try!`

**v2**: `throws`

**Migration path (easy)**: Add `try` to constructor calls.

### Events

**v1**: `var event: Event<Delegate>`, `foo.event.addHandler { ... }`

**v2**: `func event(_ handler:)`,  `foo.event { ... }`

**Migration path (easy)**: Remove `.addHandler`s.

### Collection interop

**v1**: `Array.toVector`, but broken, can't QI for `IIterable`, [issue #159]([ArrayVector does not respond to QI for IIterable · Issue #159 · thebrowsercompany/swift-winrt · GitHub](https://github.com/thebrowsercompany/swift-winrt/issues/159))

**v2**: Not provided

**Migration path (easy)**: Application can provide extension from `v1` with its limitations.

### Custom QI & COM imports

These advanced scenarios will necessarily have different code shapes due to support module differences.



## Non-breaking projection differences

### Windows header independence

**v1**: Generated C code relies on Windows headers for core types

**v2**: Generated C code only relies on C stdlib headers

### Composable generation

**v1**: Must generate low-level modules (e.g. UWP) and high-level ones (e.g. WinUI) all at once because of shared `CWinRT` module

**v2**: Designed for separate generation passes. Each module has its own ABI module.

### COM identity of Swift objects

**v1**: Not persistent. Separate wrapping every time.

**v2**: Yes. Persistent.

### Generality to arbitrary WinRTComponents

**v1**: No. Bakes in knowledge of mapping some namespaces to module names.

**v2**: Yes. Configurable.

### ActivationFactory resolution

**v1**: Via built-in `RoGetActivationFactory`. Requires manifest.

**v2**: Pluggable. Can avoid manifest.

### Error handling for properties

v1: None, implicit `try!`

v2: None on property, but separate throwing getter/setters functions exposed

### Enums

**v1**: `typealias` of C type with extensions

**v2**: Swift structs

**Migration path**: Probably transparent

### Type/member documentation

**v1**: No

**v2**: Yes, generated from documentation xml files

### Generated class boilerplate

**v1**: Visible throughout: `__x_ABI_`, `_getABI`, `from`, `init(fromAbi)`, `Overloads` class

**v2**: At end of file

### Swift objects/allocations per COM wrapper

**v1**:

- 1 for the wrapper class
- 3 per implemented interface, including default (ABI wrapper + IUnknownRef + COMPtr)
- 2 per event (add + remove handlers)

**v2**: 1 for the wrapper class

### GetActivationFactory

**v1**: One call per static interface

**v2**: One call per class + 1 query per static interface

### Internal error handling

**v1**: `try!` on much internal code: `GetActivationFactory`, `queryInterface`

**v2**: All errors thrown and bubbled to caller

## Generator codebase differences

### Language

**v1**: C++

**v2**: Swift

### Code text writing logic

**v1**: string concatenation, often including indentation

**v2**: abstraction for code structures (with few exceptions)

### Generics handling

**v1**: Special case, code duplication

**v2**: Abstracted and handled uniformly

### Value projection logic

**v1**: Several special cases throughout

**v2**: Mostly unified through `ABIProjection` abstraction

###  Tests

**v1**: [large classes](https://github.com/thebrowsercompany/swift-winrt/blob/b0cd25377f0903221d278b4e4f7799f0788cfe82/tests/test_component/cpp/test_component.idl#L164) with non-obvious semantics, many cases commented out

**v2**: factored and exhaustive

### Speed

**v1**: Probably faster generator

**v2**: Not optimized
