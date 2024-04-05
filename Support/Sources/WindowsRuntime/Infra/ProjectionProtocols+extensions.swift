import WindowsRuntime_ABI

extension BoxableProjection {
    public static func box(_ value: SwiftValue) throws -> IInspectable {
        ReferenceBox<Self>(value)
    }

    public static func isBox(_ inspectable: IInspectable) -> Bool {
        do {
            _ = try inspectable._queryInterface(ireferenceID)
            return true
        } catch {
            return false
        }
    }

    public static func unbox(_ inspectable: IInspectable) -> SwiftValue? {
        do {
            let ireference = try inspectable._queryInterface(ireferenceID, type: SWRT_WindowsFoundation_IReference.self)
            var abiValue = abiDefaultValue
            try withUnsafeMutablePointer(to: &abiValue) { abiValuePointer in
                _ = try WinRTError.throwIfFailed(ireference.pointer.pointee.VirtualTable.pointee.get_Value(ireference.pointer, abiValuePointer))
            }
            return toSwift(consuming: &abiValue)
        }
        catch {
            return nil
        }
    }
}

extension ReferenceTypeProjection {
    public static func _implement<This>(_ this: UnsafeMutablePointer<This>?, _ body: (SwiftObject) throws -> Void) -> SWRT_HResult {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return HResult.pointer.value
        }

        let implementation: SwiftObject = COMExportBase.getImplementationUnsafe(this)
        return WinRTError.catchAndOriginate { try body(implementation) }
    }

    public static func _getter<Value>(
            _ this: COMPointer?,
            _ value: UnsafeMutablePointer<Value>?,
            _ code: (SwiftObject) throws -> Value) -> SWRT_HResult {
        _implement(this) {
            guard let value else { throw HResult.Error.pointer }
            value.pointee = try code($0)
        }
    }
}

extension DelegateProjection {
    public static func box(_ value: SwiftValue) throws -> IInspectable {
        ReferenceBox<Self>(value)
    }
}

extension ComposableClassProjection {
    public static func _unwrap(_ pointer: COMPointer) -> SwiftObject? {
        COMExportedInterface.unwrap(pointer) as? SwiftObject
    }
}