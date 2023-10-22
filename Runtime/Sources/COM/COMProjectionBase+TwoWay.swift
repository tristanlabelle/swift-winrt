import CWinRTCore

extension COMProjectionBase where Projection: COMTwoWayProjection {
    public static func _getImplementation(_ pointer: Projection.COMPointer) -> Projection.SwiftObject {
        COMExport<Projection>.from(pointer).implementation
    }

    public static func _getImplementation(_ pointer: Projection.ABIValue) -> Projection.SwiftValue {
        guard let pointer else { return nil }
        return Optional(_getImplementation(pointer))
    }

    public static func _implement(_ this: Projection.ABIValue, _ body: (Projection.SwiftObject) throws -> Void) -> HRESULT {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return HResult.invalidArg.value
        }
        return HResult.catchValue { try body(_getImplementation(this)) }
    }

    public static func _getter<Value>(
            _ this: Projection.ABIValue,
            _ value: UnsafeMutablePointer<Value>?,
            _ code: (Projection.SwiftObject) throws -> Value) -> HRESULT {
        _implement(this) {
            guard let value else { throw HResult.Error.invalidArg }
            value.pointee = try code($0)
        }
    }

    public static func _queryInterface(
        _ this: Projection.ABIValue,
        _ iid: UnsafePointer<IID>?,
        _ ppvObject: UnsafeMutablePointer<UnsafeMutableRawPointer?>?) -> HRESULT {
        guard let ppvObject else { return HResult.invalidArg.value }
        ppvObject.pointee = nil

        guard let this, let iid else { return HResult.invalidArg.value }

        return HResult.catchValue {
            let unknownWithRef = try COMExport<Projection>.queryInterface(this, iid.pointee)
            ppvObject.pointee = UnsafeMutableRawPointer(unknownWithRef)
        }
    }

    public static func _addRef(_ this: Projection.ABIValue) -> UInt32 {
        guard let this else { return 0 }
        return COMExport<Projection>.addRef(this)
    }

    public static func _release(_ this: Projection.ABIValue) -> UInt32 {
        guard let this else { return 0 }
        return COMExport<Projection>.release(this)
    }
}
