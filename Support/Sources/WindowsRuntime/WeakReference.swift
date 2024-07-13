import COM
import WindowsRuntime_ABI

/// A weak reference to a WinRT object.
public final class WeakReference<Projection: ReferenceTypeProjection> {
    private var weakReference: COMReference<SWRT_IWeakReference>

    public init(_ target: Projection.SwiftObject) throws {
        guard let targetInspectable = target as? IInspectable else { throw HResult.Error.invalidArg }
        let source = try targetInspectable._queryInterface(
            uuidof(SWRT_IWeakReferenceSource.self), type: SWRT_IWeakReferenceSource.self)
        self.weakReference = .init(transferringRef: try Self.getWeakReference(source.pointer))
    }

    // Workaround compiler crash when this code is inlined
    private static func getWeakReference(
            _ source: UnsafeMutablePointer<SWRT_IWeakReferenceSource>)
            throws -> UnsafeMutablePointer<SWRT_IWeakReference> {
        var weakReference: UnsafeMutablePointer<SWRT_IWeakReference>?
        try WinRTError.throwIfFailed(source.pointee.VirtualTable.pointee.GetWeakReference(source, &weakReference))
        if let weakReference { return weakReference }
        throw HResult.Error.fail
    }

    public func resolve() throws -> Projection.SwiftObject? {
        var inspectableTarget: UnsafeMutablePointer<SWRT_IInspectable>? = nil
        var iid = GUIDProjection.toABI(Projection.interfaceID)
        try WinRTError.throwIfFailed(weakReference.pointer.pointee.VirtualTable.pointee.Resolve(
            weakReference.pointer, &iid, &inspectableTarget))
        var target = Projection.ABIPointer(OpaquePointer(inspectableTarget))
        return Projection.toSwift(consuming: &target)
    }
}