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

extension WinRTBoxableProjection {
    public static func box(_ value: SwiftValue) throws -> IInspectable {
        ReferenceBox<Self>(value)
    }

    public static func isBox(_ inspectable: IInspectable) -> Bool {
        do {
            _ = try inspectable._queryInterface(ireferenceID)
            return true
        } catch {
            return false
        }
    }

    public static func unbox(_ inspectable: IInspectable) -> SwiftValue? {
        do {
            let ireference = try inspectable._queryInterface(ireferenceID).reinterpret(to: SWRT_WindowsFoundation_IReference.self)
            var abiValue = abiDefaultValue
            try withUnsafeMutablePointer(to: &abiValue) { abiValuePointer in
                _ = try WinRTError.throwIfFailed(ireference.pointer.pointee.lpVtbl.pointee.get_Value(ireference.pointer, abiValuePointer))
            }
            return toSwift(consuming: &abiValue)
        }
        catch {
            return nil
        }
    }
}

/// Marker protocol for projections of WinRT value types into Swift.
/// Value types implement the projection protocol directly since they can't define clashing static members.
public protocol WinRTValueTypeProjection: WinRTBoxableProjection where SwiftValue == Self {}

/// Convenience protocol for projections of WinRT types into Swift.
public protocol WinRTEnumProjection: WinRTValueTypeProjection, IntegerEnumProjection {}

/// Convenience protocol for projections of WinRT structs into Swift.
public protocol WinRTStructProjection: WinRTValueTypeProjection {} // Inert structs will also conform to ABIInertProjection

/// Convenience protocol for projections of WinRT interfaces into Swift.
public protocol WinRTInterfaceProjection: WinRTProjection, COMTwoWayProjection {}

/// Convenience protocol for projections of WinRT delegates into Swift.
public protocol WinRTDelegateProjection: WinRTBoxableProjection, COMTwoWayProjection {}

extension WinRTDelegateProjection {
    public static func box(_ value: SwiftValue) throws -> IInspectable {
        ReferenceBox<Self>(value)
    }
}

/// Convenience protocol for projections of WinRT classes into Swift.
public protocol WinRTClassProjection: WinRTProjection, COMProjection {}