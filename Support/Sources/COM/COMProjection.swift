import WindowsRuntime_ABI

public typealias COMInterfaceID = GUID

/// A type which projects a COM interface to a corresponding Swift object.
/// Swift and ABI values are optional types, as COM interfaces can be null.
public protocol COMProjection: ABIProjection where SwiftValue == SwiftObject?, ABIValue == COMPointer? {
    /// The Swift type to which the COM interface is projected.
    associatedtype SwiftObject
    /// The COM interface structure.
    associatedtype COMInterface /* : COMIUnknownStruct */
    /// A pointer to the COM interface structure.
    typealias COMPointer = UnsafeMutablePointer<COMInterface>

    /// Gets the COM interface identifier.
    static var interfaceID: COMInterfaceID { get }

    // Non-nullable overloads
    static func toCOM(_ object: SwiftObject) throws -> COMReference<COMInterface>

    // Wraps a COM object into a new Swift object, without attempting to unwrap it first.
    static func _wrap(_ reference: consuming COMReference<COMInterface>) -> SwiftObject

    // Indicates whether an exported Swift object can be unwrapped back from the COM object.
    static var unwrappable: Bool { get }
}

extension COMProjection {
    // Default ABIProjection implementation
    public static var abiDefaultValue: ABIValue { nil }

    public static func toSwift(_ value: ABIValue) -> SwiftValue {
        guard let comPointer = value else { return nil }
        return toSwift(COMReference<COMInterface>(addingRef: comPointer))
    }

    public static func toSwift(consuming value: inout ABIValue) -> SwiftValue {
        guard let comPointer = value else { return nil }
        value = nil
        return toSwift(COMReference<COMInterface>(transferringRef: comPointer))
    }

    public static func toABI(_ value: SwiftValue) throws -> ABIValue {
        guard let object = value else { return nil }
        return try toCOM(object).detach()
    }

    public static func release(_ value: inout ABIValue) {
        guard let comPointer = value else { return }
        COMInterop(comPointer).release()
        value = nil
    }

    // Default COMProjection implementation
    public static var unwrappable: Bool { true }

    public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject {
        // If this was originally a Swift object, return it
        if unwrappable, let implementation: SwiftObject = COMExportBase.getImplementation(reference.pointer) {
            return implementation
        }

        // Wrap the COM object into a new Swift object
        return _wrap(consume reference)
    }
}
