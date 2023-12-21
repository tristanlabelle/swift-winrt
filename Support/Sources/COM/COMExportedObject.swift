import CWinRTCore

public struct COMExportInterface {
    public let id: COMInterfaceID
    public let queryPointer: (_ identity: COMExportedObjectCore) throws -> IUnknownPointer

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

/// Provides an object layout that can be passed as a pointer to COM consumers, with a leading virtual table pointer.
open class COMExportedObjectCore: IUnknownProtocol {
    /// Identifies that a COM object is an instance of this class.
    fileprivate static let markerInterfaceId = COMInterfaceID(0x33934271, 0x7009, 0x4EF3, 0x90F1, 0x02090D7EBD64)

    fileprivate struct COMInterface {
        public let virtualTable: UnsafeRawPointer
        public var this: Unmanaged<COMExportedObjectCore>!
    }

    fileprivate enum IdentityData {
        case own(queriableInterfaces: [COMExportInterface], agile: Bool)
        case foreign(COMExportedObjectCore)
    }

    private var comInterface: COMInterface
    private let identityData: IdentityData

    fileprivate init(virtualTable: UnsafeRawPointer, identityData: IdentityData) {
        self.comInterface = COMInterface(virtualTable: virtualTable, this: nil)
        self.identityData = identityData
        self.comInterface.this = Unmanaged.passUnretained(self)
    }

    public var identity: COMExportedObjectCore {
        switch identityData {
            case .own: self
            case .foreign(let other): other
        }
    }

    public var queriableInterfaces: [COMExportInterface] {
        switch identityData {
            case .own(let queriableInterfaces, _): queriableInterfaces
            case .foreign(let other): other.queriableInterfaces
        }
    }

    public var unknown: IUnknownPointer {
        withUnsafeMutablePointer(to: &comInterface) {
            IUnknownPointer.cast($0)
        }
    }

    // Overriden in derived class
    public var anyImplementation: Any { fatalError() }

    open func _queryInterfacePointer(_ id: COMInterfaceID) throws -> IUnknownPointer {
        switch identityData {
            case .own(let queriableInterfaces, let agile):
                if id == IUnknownProjection.id || id == Self.markerInterfaceId
                    || (agile && id == IAgileObjectProjection.id) {
                    return unknown.addingRef()
                }
                guard let interface = queriableInterfaces.first(where: { $0.id == id }) else {
                    throw HResult.Error.noInterface
                }
                return try interface.queryPointer(self)

            case .foreign(let target):
                return try target._queryInterfacePointer(id)
        }
    }

    private static func toUnmanagedUnsafe(_ this: IUnknownPointer) -> Unmanaged<COMExportedObjectCore> {
        this.withMemoryRebound(to: COMInterface.self, capacity: 1) { $0.pointee.this }
    }

    internal static func castUnsafe(_ this: IUnknownPointer) -> COMExportedObjectCore {
        toUnmanagedUnsafe(this).takeUnretainedValue()
    }

    internal static func unwrapUnsafe(_ this: IUnknownPointer) -> Any {
        castUnsafe(this).anyImplementation
    }

    @discardableResult
    internal static func addRefUnsafe(_ this: IUnknownPointer) -> UInt32 {
        let unmanaged = toUnmanagedUnsafe(this)
        _ = unmanaged.retain()
        // Best effort refcount
        return UInt32(_getRetainCount(unmanaged.takeUnretainedValue()))
    }

    @discardableResult
    internal static func releaseUnsafe(_ this: IUnknownPointer) -> UInt32 {
        let unmanaged = toUnmanagedUnsafe(this)
        let oldRetainCount = _getRetainCount(unmanaged.takeUnretainedValue())
        unmanaged.release()
        // Best effort refcount
        return UInt32(oldRetainCount - 1)
    }

    internal static func queryInterfaceUnsafe(_ this: IUnknownPointer, _ id: COMInterfaceID) throws -> IUnknownPointer {
        try castUnsafe(this)._queryInterfacePointer(id)
    }

    public static func unwrap(_ this: IUnknownPointer) -> Any? {
        // Use the marker interface to test if this is a COMExportedObject
        guard let result = try? this.queryInterface(Self.markerInterfaceId) else { return nil }
        result.release()
        return unwrapUnsafe(this)
    }
}

open class COMExportedObject<Projection: COMTwoWayProjection>: COMExportedObjectCore {
    public let implementation: Projection.SwiftObject
    public override var anyImplementation: Any { implementation }

    public init(implementation: Projection.SwiftObject, queriableInterfaces: [COMExportInterface], agile: Bool = true) {
        self.implementation = implementation
        super.init(
            virtualTable: Projection.virtualTablePointer,
            identityData: .own(queriableInterfaces: queriableInterfaces, agile: agile))
    }

    fileprivate init(implementation: Projection.SwiftObject, identity: COMExportedObjectCore) {
        self.implementation = implementation
        super.init(
            virtualTable: Projection.virtualTablePointer,
            identityData: .foreign(identity))
    }

    public var pointer: Projection.COMPointer {
        unknown.withMemoryRebound(to: Projection.COMInterface.self, capacity: 1) { $0 }
    }

    open override func _queryInterfacePointer(_ id: COMInterfaceID) throws -> IUnknownPointer {
        if id == Projection.id { return unknown.addingRef() }
        return try super._queryInterfacePointer(id)
    }

    internal static func castUnsafe(_ this: Projection.COMPointer) -> Self {
        COMExportedObjectCore.castUnsafe(IUnknownPointer.cast(this)) as! Self
    }

    internal static func unwrapUnsafe(_ this: Projection.COMPointer) -> Projection.SwiftObject {
        castUnsafe(this).implementation
    }

    @discardableResult
    internal static func addRefUnsafe(_ this: Projection.COMPointer) -> UInt32 {
        COMExportedObjectCore.addRefUnsafe(IUnknownPointer.cast(this))
    }

    @discardableResult
    internal static func releaseUnsafe(_ this: Projection.COMPointer) -> UInt32 {
        COMExportedObjectCore.releaseUnsafe(IUnknownPointer.cast(this))
    }

    internal static func queryInterfaceUnsafe(_ this: Projection.COMPointer, _ id: COMInterfaceID) throws -> IUnknownPointer {
        try COMExportedObjectCore.queryInterfaceUnsafe(IUnknownPointer.cast(this), id)
    }

    public static func unwrap(_ this: Projection.COMPointer) -> Projection.SwiftObject? {
        COMExportedObjectCore.unwrap(IUnknownPointer.cast(this)) as? Projection.SwiftObject
    }
}
