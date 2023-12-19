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

    public static func toABI(_ value: SwiftValue) throws -> ABIValue {
        guard let value else { return nil }

        let propertyValueStatics = try getPropertyValueStaticsNoRef()
        var boxed: UnsafeMutablePointer<CWinRTCore.SWRT_IInspectable>? = nil
        let result = switch value {
            case let value as UInt8: propertyValueStatics.pointee.lpVtbl.pointee.CreateUInt8(propertyValueStatics, value, &boxed)
            case let value as Int16: propertyValueStatics.pointee.lpVtbl.pointee.CreateInt16(propertyValueStatics, value, &boxed)
            case let value as UInt16: propertyValueStatics.pointee.lpVtbl.pointee.CreateUInt16(propertyValueStatics, value, &boxed)
            case let value as Int32: propertyValueStatics.pointee.lpVtbl.pointee.CreateInt32(propertyValueStatics, value, &boxed)
            case let value as UInt32: propertyValueStatics.pointee.lpVtbl.pointee.CreateUInt32(propertyValueStatics, value, &boxed)
            case let value as Int64: propertyValueStatics.pointee.lpVtbl.pointee.CreateInt64(propertyValueStatics, value, &boxed)
            case let value as UInt64: propertyValueStatics.pointee.lpVtbl.pointee.CreateUInt64(propertyValueStatics, value, &boxed)
            default: HResult.fail.value
        }
        defer { IUnknownPointer.release(boxed) }

        try WinRTError.throwIfFailed(result)
        guard let boxed else { throw HResult.Error.noInterface }

        let iid = switch Value.self {
            case is Int32.Type: COMInterfaceID(0x548CEFBD, 0xBC8A, 0x5FA0, 0x8DF2, 0x957440FC8BF4)
            case is UInt32.Type: COMInterfaceID(0x513EF3AF, 0xE784, 0x5325, 0xA91E, 0x97C2B8111CF3)
            case is UInt64.Type: COMInterfaceID(0x6755E376, 0x53BB, 0x568B, 0xA11D, 0x17239868309E)
            default: fatalError("Not implemented: \(#function) for \(Value.self)")
        }

        return try IUnknownPointer.cast(boxed).queryInterface(iid, CWinRTCore.SWRT_IReference.self)
    }

    public static func release(_ value: inout ABIValue) {
        guard let comPointer = value else { return }
        IUnknownPointer.release(comPointer)
        value = nil
    }
}