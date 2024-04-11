/// Base for classes that implement and provide identity for COM interfaces.
open class COMPrimaryExport<Projection: COMTwoWayProjection>: COMExportBase<Projection> {
    open class var implements: [COMImplements] { [] }
    open class var implementIAgileObject: Bool { true }

    public override init() {
        super.init()
    }

    open override func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        switch id {
            case Projection.interfaceID:
                return toCOM().cast()
            case IUnknownProjection.interfaceID:
                return toCOM().cast()
            case IAgileObjectProjection.interfaceID where Self.implementIAgileObject:
                return toCOM().cast()
            default:
                if let interface = Self.implements.first(where: { $0.id == id }) {
                    return interface.createCOM(identity: self)
                }
                throw HResult.Error.noInterface
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

    public init<Projection: COMTwoWayProjection>(_: Projection.Type) {
        self.id = Projection.interfaceID
        self.factory = { identity in
            COMSecondaryExport<Projection>.delegating(to: identity).toCOM().cast()
        }
    }

    public func createCOM(identity: IUnknown) -> IUnknownReference {
        factory(identity)
    }
}
