import CABI

extension COMProjectionBase {
    public func _withOutParam<ValueProjection: ABIProjection>(
            _: ValueProjection.Type,
            _ body: (UnsafeMutablePointer<ValueProjection.ABIValue>) -> HRESULT) throws -> ValueProjection.SwiftValue {
        var value = ValueProjection.abiDefaultValue
        try HResult.throwIfFailed(body(&value))
        return ValueProjection.toSwift(consuming: value)
    }

    public func _getter<Value>(
            _ function: (Projection.ABIValue, UnsafeMutablePointer<Value>?) -> HRESULT) throws -> Value {
        try withUnsafeTemporaryAllocation(of: Value.self, capacity: 1) { valueBuffer in
            let valuePointer = valueBuffer.baseAddress!
            try HResult.throwIfFailed(function(_pointer, valuePointer))
            return valuePointer.pointee
        }
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