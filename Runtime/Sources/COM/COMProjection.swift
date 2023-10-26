import CWinRTCore

/// A type which projects a COM interface to a corresponding Swift object.
/// Swift and ABI values are optional types, as COM interfaces can be null.
public protocol COMProjection: ABIProjection, IUnknownProtocol
        where SwiftValue == SwiftObject?, ABIValue == COMPointer? {
    /// The Swift type to which the COM interface is projected.
    associatedtype SwiftObject
    /// The COM interface structure.
    associatedtype COMInterface
    /// The COM interface's virtual table structure.
    associatedtype COMVirtualTable
    /// A pointer to the COM interface structure.
    typealias COMPointer = UnsafeMutablePointer<COMInterface>
    /// A pointer to the COM interface's virtual table structure.
    typealias COMVirtualTablePointer = UnsafePointer<COMVirtualTable>

    // Non-nullable overloads
    static func toSwift(copying value: COMPointer) -> SwiftObject
    static func toSwift(consuming value: COMPointer) -> SwiftObject
    static func toABI(_ value: SwiftObject) throws -> COMPointer

    /// Gets the identifier of the COM interface.
    static var iid: IID { get }
}

extension COMProjection {

    // Common implementations
    public static var abiDefaultValue: ABIValue { nil }

    public static func release(_ value: COMPointer) {
        IUnknownPointer.release(value)
    }

    // Nullable to non-nullable overload forwarding
    public static func toSwift(copying value: ABIValue) -> SwiftValue {
        guard let value else { return nil }
        return toSwift(copying: value)
    }

    public static func toSwift(consuming value: ABIValue) -> SwiftValue {
        guard let value else { return nil }
        return toSwift(consuming: value)
    }

    public static func toABI(_ value: SwiftValue) throws -> ABIValue {
        guard let value else { return nil }
        return try toABI(value)
    }

    public static func release(_ value: ABIValue) {
        if let value { release(value) }
    }
}

// Protocol for strongly-typed two-way COM interface projections into and from Swift.
public protocol COMTwoWayProjection: COMProjection {
    static var vtable: COMVirtualTablePointer { get }
}
