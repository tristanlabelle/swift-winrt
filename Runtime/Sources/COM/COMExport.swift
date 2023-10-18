import CABI

// Base class for Swift objects exported to COM
public protocol COMExportProtocol: IUnknownProtocol {
    var unknown: IUnknownPointer { get }
    var anyImplementation: Any { get }
    var identity: any COMExportProtocol { get }
    var queriableInterfaces: [COMExportInterface] { get }
}

public struct COMExportInterface {
    public let iid: IID
    public let queryPointer: (_ identity: any COMExportProtocol) throws -> IUnknownPointer

    public init<TargetProjection: COMTwoWayProjection>(_: TargetProjection.Type) {
        self.iid = TargetProjection.iid
        self.queryPointer = { identity in
            let export = COMExport<TargetProjection>(
                implementation: identity.anyImplementation as! TargetProjection.SwiftValue,
                identity: identity)
            return export.unknown.addingRef()
        }
    }
}

open class COMExport<Projection: COMTwoWayProjection>: COMExportProtocol, IUnknownProtocol {
    private struct COMInterface {
        /// Virtual function table called by COM
        public let vtable: Projection.VirtualTablePointer = Projection.vtable
        public var object: Unmanaged<COMExport<Projection>>! = nil
    }

    private enum IdentityData {
        case own(queriableInterfaces: [COMExportInterface])
        case foreign(any COMExportProtocol)
    }

    private var comInterface: COMInterface
    private let identityData: IdentityData
    public let implementation: Projection.SwiftValue
    public var anyImplementation: Any { implementation }

    public init(implementation: Projection.SwiftValue, queriableInterfaces: [COMExportInterface]) {
        self.comInterface = COMInterface()
        self.identityData = .own(queriableInterfaces: queriableInterfaces)
        self.implementation = implementation
        self.comInterface.object = Unmanaged.passUnretained(self)
    }

    fileprivate init(implementation: Projection.SwiftValue, identity: any COMExportProtocol) {
        self.comInterface = COMInterface()
        self.identityData = .foreign(identity)
        self.implementation = implementation
        self.comInterface.object = Unmanaged.passUnretained(self)
    }

    public var pointer: Projection.COMInterfacePointer {
        withUnsafeMutablePointer(to: &comInterface) {
            $0.withMemoryRebound(to: Projection.COMInterface.self, capacity: 1) { $0 }
        }
    }

    public var unknown: IUnknownPointer {
        IUnknownPointer.cast(pointer)
    }

    public var identity: any COMExportProtocol {
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

    open func _queryInterfacePointer(_ iid: IID) throws -> IUnknownPointer {
        if iid == Projection.iid { return unknown.addingRef() }
        
        switch identityData {
            case .own(let queriableInterfaces):
                if iid == IUnknownProjection.iid { return unknown.addingRef() }
                guard let interface = queriableInterfaces.first(where: { $0.iid == iid }) else {
                    throw HResult.Error.noInterface
                }
                return try interface.queryPointer(self)

            case .foreign(let target):
                return try target._queryInterfacePointer(iid)
        }
    }

    private static func cast(_ this: Projection.COMInterfacePointer) -> UnsafeMutablePointer<COMInterface> {
        this.withMemoryRebound(to: COMInterface.self, capacity: 1) { $0 }
    }

    internal static func from(_ this: Projection.COMInterfacePointer) -> COMExport<Projection> {
        cast(this).pointee.object.takeUnretainedValue()
    }

    @discardableResult
    internal static func addRef(_ this: Projection.COMInterfacePointer) -> UInt32 {
        let this = cast(this)
        _ = this.pointee.object.retain()
        // Best effort refcount
        return UInt32(_getRetainCount(this.pointee.object.takeUnretainedValue()))
    }

    @discardableResult
    internal static func release(_ this: Projection.COMInterfacePointer) -> UInt32 {
        let this = cast(this)
        let oldRetainCount = _getRetainCount(this.pointee.object.takeUnretainedValue())
        this.pointee.object.release()
        // Best effort refcount
        return UInt32(oldRetainCount - 1)
    }

    internal static func queryInterface(_ this: Projection.COMInterfacePointer, _ iid: IID) throws -> IUnknownPointer {
        try cast(this).pointee.object.takeUnretainedValue()._queryInterfacePointer(iid)
    }
}
