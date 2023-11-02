import CWinRTCore

// Base class for COM objects projected into Swift.
open class COMImport<Projection: COMProjection>: IUnknownProtocol {
    /// Gets the COM interface pointer.
    public let comPointer: Projection.COMPointer

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

    public func _queryInterfacePointer(_ iid: IID) throws -> IUnknownPointer {
        return try IUnknownPointer.cast(comPointer).queryInterface(iid)
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
}
