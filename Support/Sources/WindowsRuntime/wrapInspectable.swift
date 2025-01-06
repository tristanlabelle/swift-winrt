/// A strategy for resolving a type binding from runtime type information and static context.
/// For example, if a Foo class instance as an IFoo interface, we can look up FooBinding from the runtime type name.
public protocol InspectableTypeBindingResolver {
    func resolve(typeName: String) -> (any InspectableTypeBinding.Type)?
}

/// The global runtime binding resolver.
public var inspectableTypeBindingResolver: (any InspectableTypeBindingResolver)? = nil

/// Creates a Swift wrapper object for a COM object reference.
public func wrapInspectable<StaticBinding: InspectableTypeBinding>(
        _ reference: consuming StaticBinding.ABIReference,
        staticBinding: StaticBinding.Type) -> StaticBinding.SwiftObject {
    // The resolver can give us a more derived type so consult it first.
    let inspectablePointer = IInspectablePointer(OpaquePointer(reference.pointer))
    if let inspectableTypeBindingResolver,
            let typeName = try? COMInterop(inspectablePointer).getRuntimeClassName(),
            let inspectableTypeBinding = inspectableTypeBindingResolver.resolve(typeName: typeName) {
        if let wrapper = try? inspectableTypeBinding._wrapInspectable(COMReference(addingRef: inspectablePointer)) as? StaticBinding.SwiftObject {
            return wrapper
        }

        assertionFailure("\(inspectableTypeBinding) failed to wrap a COM object to \(StaticBinding.SwiftObject.self)")
    }

    return StaticBinding._wrap(consume reference)
}