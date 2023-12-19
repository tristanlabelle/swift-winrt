import CWinRTCore
import struct Foundation.UUID

public enum IReferenceNumericProjection<Value: Numeric>: ABIProjection {
    public typealias SwiftValue = Value?
    public typealias ABIValue = UnsafeMutablePointer<CWinRTCore.SWRT_IReference>?

    public static var abiDefaultValue: ABIValue { nil }

    public static func toSwift(_ comPointer: ABIValue) -> SwiftValue {
        guard let comPointer else { return nil }
        var value: Value = .zero
        withUnsafeMutablePointer(to: &value) { valuePointer in
            try! WinRTError.throwIfFailed(comPointer.pointee.lpVtbl.pointee.get_Value(
                comPointer, UnsafeMutableRawPointer(valuePointer)))
        }
        return value
    }

    public static func toABI(_ object: SwiftValue) throws -> ABIValue {
        // TODO: Call Windows.Foundation.PropertyValue.Create***
        throw HResult.Error.notImpl
    }

    public static func release(_ value: inout ABIValue) {
        guard let comPointer = value else { return }
        IUnknownPointer.release(comPointer)
        value = nil
    }
}