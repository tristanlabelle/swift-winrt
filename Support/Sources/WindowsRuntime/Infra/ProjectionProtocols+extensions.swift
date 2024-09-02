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
    // Shadow COMTwoWayProjection methods to use WinRTError instead of COMError
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

extension InterfaceProjection {
    // Shadow COMTwoWayProjection methods to use WinRTError instead of COMError
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

extension DelegateProjection {
    // Shadow COMTwoWayProjection methods to use WinRTError instead of COMError
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

extension ActivatableClassProjection {
    // Shadow COMTwoWayProjection methods to use WinRTError instead of COMError
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

    // Shadow COMTwoWayProjection methods to use WinRTError instead of COMError
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