import COM
import WindowsRuntime_ABI

/// Protocol for the projection of WinRT types into Swift.
public protocol WinRTProjection: ABIProjection {
    /// Gets the name of the WinRT type.
    static var typeName: String { get }
}

/// Protocol for the projection of WinRT types that can be wrapped in an IReference<T>,
/// which includes primitive types, value types and delegates.
public protocol IReferenceableProjection: WinRTProjection {
    static var ireferenceID: COMInterfaceID { get }
    static var ireferenceArrayID: COMInterfaceID { get }
    static func createIReference(_ value: SwiftValue) throws -> WindowsFoundation_IReference<SwiftValue>
    static func createIReferenceArray(_ value: [SwiftValue]) throws -> WindowsFoundation_IReferenceArray<SwiftValue>
}

/// Marker protocol for projections of WinRT value types into Swift.
/// Value types implement the projection protocol directly since they can't define clashing static members.
public protocol ValueTypeProjection: IReferenceableProjection where SwiftValue == Self {}

/// Convenience protocol for projections of WinRT types into Swift.
public protocol EnumProjection: ValueTypeProjection, IntegerEnumProjection {}

/// Convenience protocol for projections of WinRT structs into Swift.
public protocol StructProjection: ValueTypeProjection {} // Inert structs will also conform to ABIInertProjection

/// Marker protocol for projections of WinRT reference types into Swift.
public protocol ReferenceTypeProjection: WinRTProjection, COMProjection {}

/// Convenience protocol for projections of WinRT interfaces into Swift.
public protocol InterfaceProjection: ReferenceTypeProjection, COMTwoWayProjection {} // where SwiftObject: any IInspectable

/// Convenience protocol for projections of WinRT delegates into Swift.
public protocol DelegateProjection: ReferenceTypeProjection, IReferenceableProjection, COMTwoWayProjection {}

/// Convenience protocol for projections of WinRT activatable classes into Swift.
public protocol ActivatableClassProjection: ReferenceTypeProjection {} // where SwiftObject: IInspectable

/// Convenience protocol for projections of WinRT composable classes into Swift.
/// Conforms to AnyObject so that conforming types must be classes, which can be looked up using NSClassFromString.
public protocol ComposableClassProjection: ReferenceTypeProjection, AnyObject { // where SwiftObject: IInspectable
    static func _wrapObject(_ reference: consuming IInspectableReference) -> IInspectable
}