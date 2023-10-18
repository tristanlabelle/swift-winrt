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

    public func _getter<Value>(
            _ function: (Projection.ABIValue, UnsafeMutablePointer<Value>?) -> HRESULT) throws -> Value {
        try _withOutParam(IdentityProjection<Value>.self) { function(_pointer, $0) }
    }

    public func _getter<ValueProjection: ABIProjection>(
            _ function: (Projection.ABIValue, UnsafeMutablePointer<ValueProjection.ABIValue>?) -> HRESULT,
            _: ValueProjection.Type) throws -> ValueProjection.SwiftValue {
        ValueProjection.toSwift(consuming: try _getter(function))
    }

    public func _setter<Value>(
            _ function: (Projection.ABIValue, Value) -> HRESULT, 
            _ value: Value) throws {
        try HResult.throwIfFailed(function(_pointer, value))
    }

    public func _setter<ValueProjection: ABIProjection>(
            _ function: (Projection.ABIValue, ValueProjection.ABIValue) -> HRESULT,
            _ value: ValueProjection.SwiftValue,
            _: ValueProjection.Type) throws {
        let abiValue = try ValueProjection.toABI(value)
        defer { ValueProjection.release(abiValue) }
        try _setter(function, abiValue)
    }
}