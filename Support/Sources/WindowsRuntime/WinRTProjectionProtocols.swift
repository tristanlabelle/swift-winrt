import COM
import WindowsRuntime_ABI

/// Protocol for the projection of WinRT types into Swift.
public protocol WinRTProjection: ABIProjection {
    /// Gets the name of the WinRT type.
    static var typeName: String { get }
}

/// Protocol for the projection of WinRT types that can be boxed into an IInspectable,
/// which includes value types and delegates.
public protocol WinRTBoxableProjection: WinRTProjection {
    static var ireferenceID: COMInterfaceID { get }
    static func box(_ value: SwiftValue) throws -> IInspectable
}

/// Marker protocol for projections of WinRT value types into Swift.
/// Value types implement the projection protocol directly since they can't define clashing static members.
public protocol WinRTValueTypeProjection: WinRTBoxableProjection where SwiftValue == Self {}

/// Convenience protocol for projections of WinRT types into Swift.
public protocol WinRTEnumProjection: WinRTValueTypeProjection, IntegerEnumProjection {}

/// Convenience protocol for projections of WinRT structs into Swift.
public protocol WinRTStructProjection: WinRTValueTypeProjection {} // Inert structs will also conform to ABIInertProjection

/// Marker protocol for projections of WinRT reference types into Swift.
public protocol WinRTReferenceTypeProjection: WinRTProjection, COMProjection {}

/// Convenience protocol for projections of WinRT interfaces into Swift.
public protocol WinRTInterfaceProjection: WinRTReferenceTypeProjection, COMTwoWayProjection {} // where SwiftObject: any IInspectable

/// Convenience protocol for projections of WinRT delegates into Swift.
public protocol WinRTDelegateProjection: WinRTReferenceTypeProjection, WinRTBoxableProjection, COMTwoWayProjection {}

/// Convenience protocol for projections of WinRT classes into Swift.
public protocol WinRTClassProjection: WinRTReferenceTypeProjection {} // where SwiftObject: any IInspectable