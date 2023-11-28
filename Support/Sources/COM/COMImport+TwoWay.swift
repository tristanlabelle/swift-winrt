import CWinRTCore

extension COMImport where Projection: COMTwoWayProjection {
    public static func _getImplementation(_ pointer: Projection.COMPointer) -> Projection.SwiftObject {
        COMExport<Projection>.from(pointer).implementation
    }

    public static func _getImplementation(_ pointer: Projection.COMPointer?) -> Projection.SwiftObject? {
        guard let pointer else { return nil }
        return Optional(_getImplementation(pointer))
    }

    public static func _implement(_ this: Projection.COMPointer?, _ body: (Projection.SwiftObject) throws -> Void) -> CWinRTCore.SWRT_HResult {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return HResult.pointer.value
        }
        return HResult.catchValue { try body(_getImplementation(this)) }
    }

    public static func _getter<Value>(
            _ this: Projection.COMPointer?,
            _ value: UnsafeMutablePointer<Value>?,
            _ code: (Projection.SwiftObject) throws -> Value) -> CWinRTCore.SWRT_HResult {
        _implement(this) {
            guard let value else { throw HResult.Error.pointer }
            value.pointee = try code($0)
        }
    }

    public static func _queryInterface(
            _ this: Projection.COMPointer?,
            _ iid: UnsafePointer<CWinRTCore.SWRT_Guid>?,
            _ ppvObject: UnsafeMutablePointer<UnsafeMutableRawPointer?>?) -> CWinRTCore.SWRT_HResult {
        guard let ppvObject else { return HResult.pointer.value }
        ppvObject.pointee = nil

        guard let this, let iid else { return HResult.pointer.value }

        return HResult.catchValue {
            let id = GUIDProjection.toSwift(iid.pointee)
            let unknownWithRef = try COMExport<Projection>.queryInterface(this, id)
            ppvObject.pointee = UnsafeMutableRawPointer(unknownWithRef)
        }
    }

    public static func _addRef(_ this: Projection.COMPointer?) -> UInt32 {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return 1
        }
        return COMExport<Projection>.addRef(this)
    }

    public static func _release(_ this: Projection.COMPointer?) -> UInt32 {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return 0
        }
        return COMExport<Projection>.release(this)
    }
}
