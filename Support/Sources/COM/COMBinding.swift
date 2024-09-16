import COM_ABI

public typealias COMInterfaceID = GUID

/// A type which binds a COM interface to a corresponding Swift object.
/// Swift and ABI values are optional types, as COM interfaces can be null.
public protocol COMBinding: ABIBinding where SwiftValue == SwiftObject?, ABIValue == ABIPointer? {
    /// The Swift type to which the COM interface is projected.
    associatedtype SwiftObject
    /// The COM interface structure.
    associatedtype ABIStruct
    /// A pointer to the COM interface structure.
    typealias ABIPointer = UnsafeMutablePointer<ABIStruct>
    /// A reference to the COM interface structure.
    typealias ABIReference = COMReference<ABIStruct>

    /// Gets the COM interface identifier.
    static var interfaceID: COMInterfaceID { get }

    // Non-nullable overload
    static func toCOM(_ object: SwiftObject) throws -> ABIReference

    // Attempts un unwrap a COM pointer into an existing Swift object.
    static func _unwrap(_ pointer: ABIPointer) -> SwiftObject?

    // Wraps a COM object into a new Swift object, without attempting to unwrap it first.
    static func _wrap(_ reference: consuming ABIReference) -> SwiftObject
}

extension COMBinding {
    // Default ABIBinding implementation
    public static var abiDefaultValue: ABIValue { nil }

    public static func fromABI(_ value: ABIValue) -> SwiftValue {
        guard let comPointer = value else { return nil }
        return fromABI(ABIReference(addingRef: comPointer))
    }

    public static func fromABI(consuming value: inout ABIValue) -> SwiftValue {
        guard let comPointer = value else { return nil }
        value = nil
        return fromABI(ABIReference(transferringRef: comPointer))
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

    // Default COMBinding implementation
    public static func _unwrap(_ pointer: ABIPointer) -> SwiftObject? { nil }

    public static func fromABI(_ reference: consuming ABIReference) -> SwiftObject {
        if let swiftObject = _unwrap(reference.pointer) { return swiftObject }
        return _wrap(consume reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> ABIReference {
        guard let unknown = object as? COM.IUnknown else {
            throw ABIBindingError.unsupported(SwiftObject.self)
        }
        return try unknown._queryInterface(Self.self)
    }
}
