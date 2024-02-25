import CWinRTCore

// Base class for COM objects projected into Swift.
open class COMImport<Projection: COMProjection>: IUnknownProtocol {
    /// Gets the COM interop wrapper which exposes projected COM methods.
    public let _interop: COMInterop<Projection.COMInterface>

    /// Gets the COM interface pointer.
    public var _pointer: Projection.COMPointer { _interop.this }

    /// Initializes a new projection from a COM interface pointer,
    /// transferring its ownership to the newly created object.
    public required init(_transferringRef pointer: Projection.COMPointer) {
        self._interop = COMInterop(pointer)
    }

    deinit { _interop.release() }

    public func _queryInterfacePointer(_ id: COMInterfaceID) throws -> IUnknownPointer {
        try _interop.queryInterface(id)
    }

    // COMProjection implementation helpers
    public class func toSwift(transferringRef comPointer: Projection.COMPointer) -> Projection.SwiftObject {
        // If this was originally a Swift object, return it
        if let implementation: Projection.SwiftObject = COMExportBase.getImplementation(comPointer) {
            IUnknownPointer.release(comPointer)
            return implementation
        }

        // Wrap the COM object in a Swift object
        return Self(_transferringRef: comPointer) as! Projection.SwiftObject
    }

    open class func toCOM(_ object: Projection.SwiftObject) throws -> Projection.COMPointer {
        switch object {
            // If this is already a wrapped COM object, return the wrapped object
            case let comImport as Self: return IUnknownPointer.addingRef(comImport._pointer)
            // Otherwise ask the object to project itself to a COM object
            case let unknown as COM.IUnknown: return try unknown._queryInterfacePointer(Projection.self)
            default: throw ABIProjectionError.unsupported(Projection.SwiftObject.self)
        }
    }
}
