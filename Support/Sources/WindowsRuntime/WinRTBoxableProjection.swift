import COM
import WindowsRuntime_ABI

/// Represents a WinRT projection that can be boxed into an IInspectable,
/// includes value types and delegates.
public protocol WinRTBoxableProjection: ABIProjection {
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