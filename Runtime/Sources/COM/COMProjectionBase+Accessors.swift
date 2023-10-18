import CABI

extension COMProjectionBase {
    public func _withOutParam<ValueProjection: ABIProjection>(
        _: ValueProjection.Type,
        _ body: (UnsafeMutablePointer<ValueProjection.ABIValue>) -> HRESULT) throws -> ValueProjection.SwiftValue {
        try withUnsafeTemporaryAllocation(of: ValueProjection.ABIValue.self, capacity: 1) { valueBuffer in
            let valuePointer = valueBuffer.baseAddress!
            try HResult.throwIfFailed(body(valuePointer))
            return ValueProjection.toSwift(consuming: valuePointer.pointee)
        }
    }

    public func _withOutParam<ValueProjection: ABIProjection>(
        _: ValueProjection.Type,
        _ body: (UnsafeMutablePointer<ValueProjection.ABIValue?>) -> HRESULT) throws -> ValueProjection.SwiftValue? {
        try _withOutParam(OptionalProjection<ValueProjection>.self, body)
    }

    public func _getter<Value>(
            _ function: (Projection.COMInterfacePointer?, UnsafeMutablePointer<Value>?) -> HRESULT) throws -> Value {
        try _withOutParam(IdentityProjection<Value>.self) { function(_pointer, $0) }
    }

    public func _getter<ValueProjection: ABIProjection>(
            _ function: (Projection.COMInterfacePointer?, UnsafeMutablePointer<ValueProjection.ABIValue>?) -> HRESULT,
            _: ValueProjection.Type) throws -> ValueProjection.SwiftValue {
        ValueProjection.toSwift(consuming: try _getter(function))
    }

    public func _getter<ValueProjection: ABIProjection>(
            _ function: (Projection.COMInterfacePointer?, UnsafeMutablePointer<ValueProjection.ABIValue?>?) -> HRESULT,
            _: ValueProjection.Type) throws -> ValueProjection.SwiftValue? {
        try _getter(function, OptionalProjection<ValueProjection>.self)
    }

    public func _setter<Value>(
            _ function: (Projection.COMInterfacePointer?, Value) -> HRESULT, 
            _ value: Value) throws {
        try HResult.throwIfFailed(function(_pointer, value))
    }

    public func _setter<ValueProjection: ABIProjection>(
            _ function: (Projection.COMInterfacePointer?, ValueProjection.ABIValue) -> HRESULT,
            _ value: ValueProjection.SwiftValue,
            _: ValueProjection.Type) throws {
        let abiValue = try ValueProjection.toABI(value)
        defer { ValueProjection.release(abiValue) }
        try _setter(function, abiValue)
    }

    public func _setter<ValueProjection: ABIProjection>(
            _ function: (Projection.COMInterfacePointer?, ValueProjection.ABIValue?) -> HRESULT,
            _ value: ValueProjection.SwiftValue?,
            _: ValueProjection.Type) throws {
        try _setter(function, value, OptionalProjection<ValueProjection>.self)
    }
}