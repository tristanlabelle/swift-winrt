import CWinRTCore

extension COMImport {
    public func _withOutParam<ValueProjection: ABIProjection>(
            _: ValueProjection.Type,
            _ body: (UnsafeMutablePointer<ValueProjection.ABIValue>) -> CWinRTCore.ABI_HResult) throws -> ValueProjection.SwiftValue {
        var value = ValueProjection.abiDefaultValue
        try HResult.throwIfFailed(body(&value))
        return ValueProjection.toSwift(consuming: &value)
    }

    public func _getter<Value>(
            _ function: (Projection.ABIValue, UnsafeMutablePointer<Value>?) -> CWinRTCore.ABI_HResult) throws -> Value {
        try withUnsafeTemporaryAllocation(of: Value.self, capacity: 1) { valueBuffer in
            let valuePointer = valueBuffer.baseAddress!
            try HResult.throwIfFailed(function(comPointer, valuePointer))
            return valuePointer.pointee
        }
    }

    public func _getter<ValueProjection: ABIProjection>(
            _ function: (Projection.ABIValue, UnsafeMutablePointer<ValueProjection.ABIValue>?) -> CWinRTCore.ABI_HResult,
            _: ValueProjection.Type) throws -> ValueProjection.SwiftValue {
        var value = try _getter(function)
        return ValueProjection.toSwift(consuming: &value)
    }

    public func _setter<Value>(
            _ function: (Projection.ABIValue, Value) -> CWinRTCore.ABI_HResult, 
            _ value: Value) throws {
        try HResult.throwIfFailed(function(comPointer, value))
    }

    public func _setter<ValueProjection: ABIProjection>(
            _ function: (Projection.ABIValue, ValueProjection.ABIValue) -> CWinRTCore.ABI_HResult,
            _ value: ValueProjection.SwiftValue,
            _: ValueProjection.Type) throws {
        var abiValue = try ValueProjection.toABI(value)
        defer { ValueProjection.release(&abiValue) }
        try _setter(function, abiValue)
    }
}