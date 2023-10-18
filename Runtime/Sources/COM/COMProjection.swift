import CABI

/// A type which projects a COM interface to a corresponding Swift object.
/// Swift and ABI values are optional types, as COM interfaces can be null.
public protocol COMProjection: ABIProjection, IUnknownProtocol
        where SwiftValue == SwiftObject?, ABIValue == COMInterfacePointer? {
    /// The Swift type to which the COM interface is projected.
    associatedtype SwiftObject
    /// The COM interface structure.
    associatedtype COMInterface
    /// The COM interface's virtual table structure.
    associatedtype COMVirtualTable
    /// A pointer to the COM interface structure.
    typealias COMInterfacePointer = UnsafeMutablePointer<COMInterface>
    /// A pointer to the COM interface's virtual table structure.
    typealias COMVirtualTablePointer = UnsafePointer<COMVirtualTable>

    /// Gets the Swift object corresponding to the COM interface.
    var swiftObject: SwiftObject { get }

    /// Gets the COM interface pointer.
    var _pointer: COMInterfacePointer { get }

    /// Initializes a new projection from a COM interface pointer,
    /// transferring its ownership to the newly created object.
    init(transferringRef pointer: COMInterfacePointer)

    /// Gets the identifier of the COM interface.
    static var iid: IID { get }
}

extension COMProjection {
    public var _unknown: IUnknownPointer {
        IUnknownPointer.cast(_pointer)
    }

    public var _vtable: COMVirtualTable {
        _read {
            let unknownVTable = UnsafePointer(_unknown.pointee.lpVtbl!)
            let pointer = unknownVTable.withMemoryRebound(to: COMVirtualTable.self, capacity: 1) { $0 }
            yield pointer.pointee
        }
    }

    public var _unsafeRefCount: UInt32 { _unknown._unsafeRefCount }

    public init(_ pointer: COMInterfacePointer) {
        IUnknownPointer.addRef(pointer)
        self.init(transferringRef: pointer)
    }

    public static func toSwift(copying value: ABIValue) -> SwiftValue {
        guard let value else { return nil }
        return Self(value).swiftObject
    }

    public static func toSwift(consuming value: ABIValue) -> SwiftValue {
        guard let value else { return nil }
        return Self(transferringRef: value).swiftObject
    }

    public static func toABI(_ value: SwiftValue) throws -> ABIValue {
        guard let value else { return nil }
        switch value {
            case let object as COMProjectionBase<Self>:
                return IUnknownPointer.addingRef(object._pointer)

            case let unknown as IUnknown:
                return try unknown._queryInterfacePointer(Self.self)

            default:
                throw ABIProjectionError.unsupported(SwiftValue.self)
        }
    }

    public static func release(_ value: ABIValue) {
        if let value { IUnknownPointer.release(value) }
    }
}

// Protocol for strongly-typed two-way COM interface projections into and from Swift.
public protocol COMTwoWayProjection: COMProjection {
    static var vtable: COMVirtualTablePointer { get }
}
