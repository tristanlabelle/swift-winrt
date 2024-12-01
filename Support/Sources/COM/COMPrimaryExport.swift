/// Base for Swift classes that implement one or more COM interfaces and owns the COM object identity,
/// meaning that they own the object returned when using QueryInterface for IUnknown.
/// The generic Binding parameter determines the virtual table of the identity object.
open class COMPrimaryExport<Binding: COMTwoWayBinding>: COMExportBase<Binding> {
    /// Gets the interfaces that can be queried for using queryInterface.
    open class var queriableInterfaces: [any COMTwoWayBinding.Type] { [] }
    open class var implementIAgileObject: Bool { true }
    open class var implementFreeThreadedMarshaling: Bool { implementIAgileObject }

    public override init() {
        super.init()
    }

    open override func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        switch id {
            case Binding.interfaceID:
                return toCOM().cast()
            case IUnknownBinding.interfaceID:
                return toCOM().cast()
            case IAgileObjectBinding.interfaceID where Self.implementIAgileObject:
                return toCOM().cast()
            case FreeThreadedMarshalBinding.interfaceID where Self.implementFreeThreadedMarshaling:
                return try FreeThreadedMarshal(self).toCOM().cast()
            default:
                if let interfaceBinding = Self.queriableInterfaces.first(where: { $0.interfaceID == id }) {
                    return COMDelegatingExport(virtualTable: interfaceBinding.virtualTablePointer, implementer: self).toCOM()
                }
                throw COMError.noInterface
        }
    }
}
