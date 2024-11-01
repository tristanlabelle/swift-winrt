import WindowsRuntime_ABI
import SWRT_WindowsFoundation

extension ClosedEnumBinding {
    public static var abiDefaultValue: RawValue { RawValue.zero }
    public static func fromABI(_ value: RawValue) -> Self { Self(rawValue: value)! }
    public static func toABI(_ value: Self) -> RawValue { value.rawValue }
}

extension IReferenceableBinding {
    public typealias IReferenceToOptional = IReferenceToOptionalBinding<Self>

    public static func createIReference(_ value: SwiftValue) throws -> WindowsFoundation_IReference<SwiftValue> {
        ReferenceImpl<Self>(value)
    }

    public static func createIReferenceArray(_ value: [SwiftValue]) throws -> WindowsFoundation_IReferenceArray<SwiftValue> {
        ReferenceArrayImpl<Self>(value)
    }
}

extension ReferenceTypeBinding {
    // Shadow COMTwoWayBinding methods to use WinRTError instead of COMError
    public static func _implement<This>(_ this: UnsafeMutablePointer<This>?, _ body: (SwiftObject) throws -> Void) -> SWRT_HResult {
        guard let this else { return WinRTError.toABI(hresult: HResult.pointer, message: "WinRT 'this' pointer was null") }
        let implementation: SwiftObject = COMEmbedding.getImplementationOrCrash(this)
        return WinRTError.toABI { try body(implementation) }
    }

    public static func _getter<Value>(_ this: ABIPointer?, _ value: UnsafeMutablePointer<Value>?, _ code: (SwiftObject) throws -> Value) -> SWRT_HResult {
        _implement(this) {
            guard let value else { throw COMError.pointer }
            value.pointee = try code($0)
        }
    }
}

extension InterfaceBinding {
    // Shadow COMTwoWayBinding methods to use WinRTError instead of COMError
    public static func _implement<This>(_ this: UnsafeMutablePointer<This>?, _ body: (SwiftObject) throws -> Void) -> SWRT_HResult {
        guard let this else { return WinRTError.toABI(hresult: HResult.pointer, message: "WinRT 'this' pointer was null") }
        let implementation: SwiftObject = COMEmbedding.getImplementationOrCrash(this)
        return WinRTError.toABI { try body(implementation) }
    }

    public static func _getter<Value>(_ this: ABIPointer?, _ value: UnsafeMutablePointer<Value>?, _ code: (SwiftObject) throws -> Value) -> SWRT_HResult {
        _implement(this) {
            guard let value else { throw COMError.pointer }
            value.pointee = try code($0)
        }
    }
}

extension DelegateBinding {
    // Shadow COMTwoWayBinding methods to use WinRTError instead of COMError
    public static func _implement<This>(_ this: UnsafeMutablePointer<This>?, _ body: (SwiftObject) throws -> Void) -> SWRT_HResult {
        guard let this else { return WinRTError.toABI(hresult: HResult.pointer, message: "WinRT 'this' pointer was null") }
        let implementation: SwiftObject = COMEmbedding.getImplementationOrCrash(this)
        return WinRTError.toABI { try body(implementation) }
    }

    public static func _getter<Value>(_ this: ABIPointer?, _ value: UnsafeMutablePointer<Value>?, _ code: (SwiftObject) throws -> Value) -> SWRT_HResult {
        _implement(this) {
            guard let value else { throw COMError.pointer }
            value.pointee = try code($0)
        }
    }
}

extension RuntimeClassBinding {
    public static func _wrapObject(_ reference: consuming IInspectableReference) throws -> IInspectable {
        try _wrap(reference.queryInterface(interfaceID)) as! IInspectable
    }

    // Shadow COMTwoWayBinding methods to use WinRTError instead of COMError
    public static func _implement<This>(_ this: UnsafeMutablePointer<This>?, _ body: (SwiftObject) throws -> Void) -> SWRT_HResult {
        guard let this else { return WinRTError.toABI(hresult: HResult.pointer, message: "WinRT 'this' pointer was null") }
        let implementation: SwiftObject = COMEmbedding.getImplementationOrCrash(this)
        return WinRTError.toABI { try body(implementation) }
    }

    public static func _getter<Value>(_ this: ABIPointer?, _ value: UnsafeMutablePointer<Value>?, _ code: (SwiftObject) throws -> Value) -> SWRT_HResult {
        _implement(this) {
            guard let value else { throw COMError.pointer }
            value.pointee = try code($0)
        }
    }
}

extension ComposableClassBinding {
    public static func fromABI(consuming value: inout ABIValue) -> SwiftValue {
        guard let pointer = value else { return nil }
        let reference = COMReference(transferringRef: pointer)
        if let swiftObject = _unwrap(reference.pointer) { return swiftObject }
        return swiftWrapperFactory.create(reference, staticBinding: Self.self)
    }

    public static func _unwrap(_ pointer: ABIPointer) -> SwiftObject? {
        COMEmbedding.getImplementation(pointer, type: SwiftObject.self)
    }
}