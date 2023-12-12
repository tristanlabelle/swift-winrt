import CWinRTCore

public protocol COMExportedObjectProtocol: IUnknownProtocol {
    var unknown: IUnknownPointer { get }
    var anyImplementation: Any { get }
    var identity: any COMExportedObjectProtocol { get }
    var queriableInterfaces: [COMExportInterface] { get }
}

public struct COMExportInterface {
    public let id: COMInterfaceID
    public let queryPointer: (_ identity: any COMExportedObjectProtocol) throws -> IUnknownPointer

    public init<TargetProjection: COMTwoWayProjection>(_: TargetProjection.Type) {
        self.id = TargetProjection.id
        self.queryPointer = { identity in
            let export = COMExportedObject<TargetProjection>(
                implementation: identity.anyImplementation as! TargetProjection.SwiftObject,
                identity: identity)
            return export.unknown.addingRef()
        }
    }
}

open class COMExportedObject<Projection: COMTwoWayProjection>: COMExportedObjectProtocol, IUnknownProtocol {
    private struct COMInterface {
        /// Virtual function table called by COM
        public let virtualTablePointer: Projection.COMVirtualTablePointer = Projection.virtualTablePointer
        public var object: Unmanaged<COMExportedObject<Projection>>! = nil
    }

    private enum IdentityData {
        case own(queriableInterfaces: [COMExportInterface])
        case foreign(any COMExportedObjectProtocol)
    }

    private var comInterface: COMInterface
    private let identityData: IdentityData
    public let implementation: Projection.SwiftObject
    public var anyImplementation: Any { implementation }

    public init(implementation: Projection.SwiftObject, queriableInterfaces: [COMExportInterface]) {
        self.comInterface = COMInterface()
        self.identityData = .own(queriableInterfaces: queriableInterfaces)
        self.implementation = implementation
        self.comInterface.object = Unmanaged.passUnretained(self)
    }

    fileprivate init(implementation: Projection.SwiftObject, identity: any COMExportedObjectProtocol) {
        self.comInterface = COMInterface()
        self.identityData = .foreign(identity)
        self.implementation = implementation
        self.comInterface.object = Unmanaged.passUnretained(self)
    }

    public var pointer: Projection.COMPointer {
        withUnsafeMutablePointer(to: &comInterface) {
            $0.withMemoryRebound(to: Projection.COMInterface.self, capacity: 1) { $0 }
        }
    }

    public var unknown: IUnknownPointer {
        IUnknownPointer.cast(pointer)
    }

    public var identity: any COMExportedObjectProtocol {
        switch identityData {
            case .own: self
            case .foreign(let other): other
        }
    }

    public var queriableInterfaces: [COMExportInterface] {
        switch identityData {
            case .own(let queriableInterfaces): queriableInterfaces
            case .foreign(let other): other.queriableInterfaces
        }
    }

    open func _queryInterfacePointer(_ id: COMInterfaceID) throws -> IUnknownPointer {
        if id == Projection.id { return unknown.addingRef() }
        
        switch identityData {
            case .own(let queriableInterfaces):
                if id == IUnknownProjection.id { return unknown.addingRef() }
                guard let interface = queriableInterfaces.first(where: { $0.id == id }) else {
                    throw HResult.Error.noInterface
                }
                return try interface.queryPointer(self)

            case .foreign(let target):
                return try target._queryInterfacePointer(id)
        }
    }

    private static func cast(_ this: Projection.COMPointer) -> UnsafeMutablePointer<COMInterface> {
        this.withMemoryRebound(to: COMInterface.self, capacity: 1) { $0 }
    }

    internal static func from(_ this: Projection.COMPointer) -> COMExportedObject<Projection> {
        cast(this).pointee.object.takeUnretainedValue()
    }

    @discardableResult
    internal static func addRef(_ this: Projection.COMPointer) -> UInt32 {
        let this = cast(this)
        _ = this.pointee.object.retain()
        // Best effort refcount
        return UInt32(_getRetainCount(this.pointee.object.takeUnretainedValue()))
    }

    @discardableResult
    internal static func release(_ this: Projection.COMPointer) -> UInt32 {
        let this = cast(this)
        let oldRetainCount = _getRetainCount(this.pointee.object.takeUnretainedValue())
        this.pointee.object.release()
        // Best effort refcount
        return UInt32(oldRetainCount - 1)
    }

    internal static func queryInterface(_ this: Projection.COMPointer, _ id: COMInterfaceID) throws -> IUnknownPointer {
        try cast(this).pointee.object.takeUnretainedValue()._queryInterfacePointer(id)
    }
}
