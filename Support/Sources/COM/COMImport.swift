import WindowsRuntime_ABI

// Base class for COM objects projected into Swift.
open class COMImport<Projection: COMProjection>: IUnknownProtocol {
    /// A reference to the underlying COM object.
    public let _reference: COMReference<Projection.COMInterface>

    /// A pointer to the underlying COM object.
    public var _pointer: UnsafeMutablePointer<Projection.COMInterface> { _reference.pointer }

    /// The interop wrapper for the underlying COM object.
    public var _interop: COMInterop<Projection.COMInterface> { _reference.interop }

    /// Initializes a new projection from a COM object reference.
    public required init(_wrapping reference: consuming COMReference<Projection.COMInterface>) {
        self._reference = reference
    }

    public func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        try _reference.interop.queryInterface(id)
    }

    // COMProjection implementation helpers
    public class func toSwift(_ reference: consuming COMReference<Projection.COMInterface>) -> Projection.SwiftObject {
        // If this was originally a Swift object, return it
        if let implementation: Projection.SwiftObject = COMExportBase.getImplementation(reference.pointer) {
            return implementation
        }

        // Wrap the COM object in a Swift object
        return Self(_wrapping: consume reference) as! Projection.SwiftObject
    }

    open class func toCOM(_ object: Projection.SwiftObject) throws -> COMReference<Projection.COMInterface> {
        switch object {
            // If this is already a wrapped COM object, return the wrapped object
            case let comImport as Self: return comImport._reference.clone()
            // Otherwise ask the object to project itself to a COM object
            case let unknown as COM.IUnknown: return try unknown._queryInterface(Projection.self)
            default: throw ABIProjectionError.unsupported(Projection.SwiftObject.self)
        }
    }
}
