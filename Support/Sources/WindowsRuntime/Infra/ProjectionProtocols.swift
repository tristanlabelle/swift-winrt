import COM
import WindowsRuntime_ABI

/// Protocol for the projection of WinRT types into Swift.
public protocol WinRTProjection: ABIProjection {
    /// Gets the name of the WinRT type.
    static var typeName: String { get }
}

/// Protocol for the projection of WinRT types that can be boxed into an IInspectable,
/// which includes value types and delegates.
public protocol BoxableProjection: WinRTProjection {
    static var ireferenceID: COMInterfaceID { get }
    static func box(_ value: SwiftValue) throws -> IInspectable
}

/// Marker protocol for projections of WinRT value types into Swift.
/// Value types implement the projection protocol directly since they can't define clashing static members.
public protocol ValueTypeProjection: BoxableProjection where SwiftValue == Self {}

/// Convenience protocol for projections of WinRT types into Swift.
public protocol EnumProjection: ValueTypeProjection, IntegerEnumProjection {}

/// Convenience protocol for projections of WinRT structs into Swift.
public protocol StructProjection: ValueTypeProjection {} // Inert structs will also conform to ABIInertProjection

/// Marker protocol for projections of WinRT reference types into Swift.
public protocol ReferenceTypeProjection: WinRTProjection, COMProjection {}

/// Convenience protocol for projections of WinRT interfaces into Swift.
public protocol InterfaceProjection: ReferenceTypeProjection, COMTwoWayProjection {} // where SwiftObject: any IInspectable

/// Convenience protocol for projections of WinRT delegates into Swift.
public protocol DelegateProjection: ReferenceTypeProjection, BoxableProjection, COMTwoWayProjection {}

/// Convenience protocol for projections of WinRT classes into Swift.
public protocol ActivatableClassProjection: ReferenceTypeProjection {} // where SwiftObject: any IInspectable
public protocol ComposableClassProjection: ReferenceTypeProjection {} // where SwiftObject: any IInspectable