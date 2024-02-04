import CWinRTCore

// Base class for COM objects projected into Swift.
open class COMImport<Projection: COMProjection>: IUnknownProtocol {
    /// Gets the COM interface pointer.
    public let comPointer: Projection.COMPointer
    public var _interop: COMInterop<Projection.COMInterface> { COMInterop(comPointer) }

    /// Gets the Swift object corresponding to the COM interface.
    open var swiftObject: Projection.SwiftObject { self as! Projection.SwiftObject }

    /// Initializes a new projection from a COM interface pointer,
    /// transferring its ownership to the newly created object.
    public required init(transferringRef pointer: Projection.COMPointer) {
        self.comPointer = pointer
    }

    public convenience init(_ pointer: Projection.COMPointer) {
        IUnknownPointer.addRef(pointer)
        self.init(transferringRef: pointer)
    }

    deinit { IUnknownPointer.release(comPointer) }

    public func _queryInterfacePointer(_ id: COMInterfaceID) throws -> IUnknownPointer {
        try _interop.queryInterface(id)
    }

    public var _unknown: IUnknownPointer {
        IUnknownPointer.cast(comPointer)
    }

    public var _vtable: Projection.COMVirtualTable {
        _read {
            let unknownVTable = UnsafePointer(_unknown.pointee.lpVtbl!)
            let pointer = unknownVTable.withMemoryRebound(to: Projection.COMVirtualTable.self, capacity: 1) { $0 }
            yield pointer.pointee
        }
    }

    public var _unsafeRefCount: UInt32 { _unknown._unsafeRefCount }

    // COMProjection implementation helpers
    public static func toSwift(transferringRef comPointer: Projection.COMPointer) -> Projection.SwiftObject {
        // If this was originally a Swift object, return it
        if let implementation = COMExportBase.getImplementation(comPointer, projection: Projection.self) {
            IUnknownPointer.release(comPointer)
            return implementation
        }

        // Wrap the COM object in a Swift object
        return Self(transferringRef: comPointer).swiftObject
    }

    open class func toCOM(_ object: Projection.SwiftObject) throws -> Projection.COMPointer {
        switch object {
            // If this is already a wrapped COM object, return the wrapped object
            case let comImport as Self: return IUnknownPointer.addingRef(comImport.comPointer)
            // Otherwise ask the object to project itself to a COM object
            case let unknown as COM.IUnknown: return try unknown._queryInterfacePointer(Projection.self)
            default: throw ABIProjectionError.unsupported(Projection.SwiftObject.self)
        }
    }
}
