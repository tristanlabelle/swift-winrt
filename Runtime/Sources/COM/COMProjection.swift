import CABI

// A type which projects a COM interface to a corresponding Swift value.
public protocol COMProjection: ABIProjection, IUnknownProtocol where ABIValue == CPointer {
    associatedtype CStruct
    associatedtype CVTableStruct
    typealias CPointer = UnsafeMutablePointer<CStruct>
    typealias CVTablePointer = UnsafePointer<CVTableStruct>

    var swiftValue: SwiftValue { get }
    var _pointer: CPointer { get }

    init(transferringRef pointer: CPointer)

    static var iid: IID { get }
}

extension COMProjection {
    public var _unknown: IUnknownPointer {
        IUnknownPointer.cast(_pointer)
    }

    public var _vtable: CVTableStruct {
        _read {
            let unknownVTable = UnsafePointer(_unknown.pointee.lpVtbl!)
            let pointer = unknownVTable.withMemoryRebound(to: CVTableStruct.self, capacity: 1) { $0 }
            yield pointer.pointee
        }
    }

    public var _unsafeRefCount: UInt32 { _unknown._unsafeRefCount }

    public init(_ pointer: CPointer) {
        IUnknownPointer.addRef(pointer)
        self.init(transferringRef: pointer)
    }

    public static func toSwift(copying value: ABIValue) -> SwiftValue {
        Self(value).swiftValue
    }

    public static func toSwift(consuming value: ABIValue) -> SwiftValue {
        Self(transferringRef: value).swiftValue
    }

    public static func toABI(_ value: SwiftValue) throws -> ABIValue {
        switch value {
            case let object as COMProjectionBase<Self>:
                return IUnknownPointer.addingRef(object._pointer)

            case let unknown as IUnknown:
                return try unknown._queryInterfacePointer(Self.self)

            default:
                throw ABIProjectionError.unsupported(SwiftValue.self)
        }
    }

    public static func release(_ pointer: CPointer) {
        IUnknownPointer.release(pointer)
    }
}

// Protocol for strongly-typed two-way COM interface projections into and from Swift.
public protocol COMTwoWayProjection: COMProjection {
    static var vtable: CVTablePointer { get }
}
