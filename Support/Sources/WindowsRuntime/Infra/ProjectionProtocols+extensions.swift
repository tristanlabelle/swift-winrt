import WindowsRuntime_ABI
import SWRT_WindowsFoundation

extension IReferenceableProjection {
    public typealias IReferenceToOptional = IReferenceToOptionalProjection<Self>

    public static func createIReference(_ value: SwiftValue) throws -> WindowsFoundation_IReference<SwiftValue> {
        ReferenceImpl<Self>(value)
    }

    public static func createIReferenceArray(_ value: [SwiftValue]) throws -> WindowsFoundation_IReferenceArray<SwiftValue> {
        ReferenceArrayImpl<Self>(value)
    }
}

extension ReferenceTypeProjection {
    public static func _implement<This>(_ this: UnsafeMutablePointer<This>?, _ body: (SwiftObject) throws -> Void) -> SWRT_HResult {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return HResult.pointer.value
        }

        let implementation: SwiftObject = COMEmbedding.getImplementationOrCrash(this)
        return WinRTError.catchAndOriginate { try body(implementation) }
    }

    public static func _getter<Value>(
            _ this: ABIPointer?,
            _ value: UnsafeMutablePointer<Value>?,
            _ code: (SwiftObject) throws -> Value) -> SWRT_HResult {
        _implement(this) {
            guard let value else { throw HResult.Error.pointer }
            value.pointee = try code($0)
        }
    }
}

extension ComposableClassProjection {
    public static func toSwift(consuming value: inout ABIValue) -> SwiftValue {
        guard let pointer = value else { return nil }
        let reference = COMReference(transferringRef: pointer)
        if let swiftObject = _unwrap(reference.pointer) { return swiftObject }
        return swiftWrapperFactory.create(reference, projection: Self.self)
    }

    public static func _unwrap(_ pointer: ABIPointer) -> SwiftObject? {
        COMEmbedding.getImplementation(pointer, type: SwiftObject.self)
    }

    public static func _wrapObject(_ reference: consuming IInspectableReference) -> IInspectable {
        try! _wrap(reference.queryInterface(interfaceID)) as! IInspectable
    }
}