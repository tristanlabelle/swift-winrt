import COM
import WindowsRuntime_ABI

/// A weak reference to a WinRT object.
public final class WeakReference<Projection: ReferenceTypeProjection> {
    private var weakReference: COMReference<SWRT_IWeakReference>

    public init(_ target: Projection.SwiftObject) throws {
        guard let targetInspectable = target as? IInspectable else { throw HResult.Error.invalidArg }
        let source = try targetInspectable._queryInterface(
            SWRT_IWeakReferenceSource.iid, type: SWRT_IWeakReferenceSource.self)
        var weakReference: UnsafeMutablePointer<SWRT_IWeakReference>?
        try WinRTError.throwIfFailed(source.pointer.pointee.VirtualTable.pointee.GetWeakReference(source.pointer, &weakReference))
        guard let weakReference else { throw HResult.Error.fail }
        self.weakReference = .init(transferringRef: weakReference)
    }

    public func resolve() throws -> Projection.SwiftObject? {
        var inspectableTarget: UnsafeMutablePointer<SWRT_IInspectable>? = nil
        var iid = GUIDProjection.toABI(Projection.interfaceID)
        try WinRTError.throwIfFailed(weakReference.pointer.pointee.VirtualTable.pointee.Resolve(
            weakReference.pointer, &iid, &inspectableTarget))
        var target = Projection.COMPointer(OpaquePointer(inspectableTarget))
        return Projection.toSwift(consuming: &target)
    }
}