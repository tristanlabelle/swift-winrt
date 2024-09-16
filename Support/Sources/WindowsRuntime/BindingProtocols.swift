import COM
import WindowsRuntime_ABI

/// Protocol for bindings of WinRT types into Swift.
public protocol WinRTBinding: ABIBinding {
    /// Gets the name of the WinRT type.
    static var typeName: String { get }
}

/// Protocol for bindings of WinRT types that can be wrapped in an IReference<T>,
/// which includes primitive types, value types and delegates.
public protocol IReferenceableBinding: WinRTBinding {
    static var ireferenceID: COMInterfaceID { get }
    static var ireferenceArrayID: COMInterfaceID { get }
    static func createIReference(_ value: SwiftValue) throws -> WindowsFoundation_IReference<SwiftValue>
    static func createIReferenceArray(_ value: [SwiftValue]) throws -> WindowsFoundation_IReferenceArray<SwiftValue>
}

/// Marker protocol for bindings of WinRT value types into Swift.
/// Value types implement the binding protocol directly since they can't define clashing static members.
public protocol ValueTypeBinding: IReferenceableBinding where SwiftValue == Self {}

/// Convenience protocol for bindings of WinRT enums into Swift.
public protocol OpenEnumBinding: ValueTypeBinding, COM.OpenEnumBinding {}
public protocol ClosedEnumBinding: ValueTypeBinding, COM.ClosedEnumBinding {}

/// Convenience protocol for bindings of WinRT structs into Swift.
public protocol StructBinding: ValueTypeBinding {} // Inert structs will also conform to PODBinding

/// Marker protocol for bindings of WinRT reference types into Swift.
public protocol ReferenceTypeBinding: WinRTBinding, COMBinding {}

/// Convenience protocol for bindings of WinRT interfaces into Swift.
public protocol InterfaceBinding: ReferenceTypeBinding, COMTwoWayBinding {} // where SwiftObject: any IInspectable

/// Convenience protocol for bindings of WinRT delegates into Swift.
public protocol DelegateBinding: ReferenceTypeBinding, IReferenceableBinding, COMTwoWayBinding {}

/// Convenience protocol for bindings of WinRT activatable classes into Swift.
public protocol ActivatableClassBinding: ReferenceTypeBinding {} // where SwiftObject: IInspectable

/// Convenience protocol for bindings of WinRT composable classes into Swift.
/// Conforms to AnyObject so that conforming types must be classes, which can be looked up using NSClassFromString.
public protocol ComposableClassBinding: ReferenceTypeBinding, AnyObject { // where SwiftObject: IInspectable
    static func _wrapObject(_ reference: consuming IInspectableReference) -> IInspectable
}