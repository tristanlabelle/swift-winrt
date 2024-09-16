/// Base for Swift classes that implement one or more COM interfaces and owns the COM object identity,
/// meaning that they own the object returned when using QueryInterface for IUnknown.
/// The generic Binding parameter determines the virtual table of the identity object.
open class COMPrimaryExport<Binding: COMTwoWayBinding>: COMExportBase<Binding> {
    open class var implements: [COMImplements] { [] }
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
                if let interface = Self.implements.first(where: { $0.id == id }) {
                    return interface.createCOM(identity: self)
                }
                throw COMError.noInterface
        }
    }
}

/// Declares an implemented COM interface for COMPrimaryExport-derived classes.
public struct COMImplements {
    public typealias Factory = (_ identity: IUnknown) -> IUnknownReference

    public let id: COMInterfaceID
    private let factory: Factory

    public init(id: COMInterfaceID, factory: @escaping Factory) {
        self.id = id
        self.factory = factory
    }

    public init<Binding: COMTwoWayBinding>(_: Binding.Type) {
        self.id = Binding.interfaceID
        self.factory = { identity in
            COMSecondaryExport<Binding>.delegating(to: identity).toCOM().cast()
        }
    }

    public func createCOM(identity: IUnknown) -> IUnknownReference {
        factory(identity)
    }
}
