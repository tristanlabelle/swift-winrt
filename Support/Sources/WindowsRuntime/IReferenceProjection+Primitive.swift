import COM
import CWinRTCore
import struct Foundation.UUID

extension IReferenceProjection {
    public typealias Bool = Primitive<Bool8Projection>
    public typealias UInt8 = Primitive<NumericProjection<Swift.UInt8>>
    public typealias Int16 = Primitive<NumericProjection<Swift.Int16>>
    public typealias UInt16 = Primitive<NumericProjection<Swift.UInt16>>
    public typealias Int32 = Primitive<NumericProjection<Swift.Int32>>
    public typealias UInt32 = Primitive<NumericProjection<Swift.UInt32>>
    public typealias Int64 = Primitive<NumericProjection<Swift.Int64>>
    public typealias UInt64 = Primitive<NumericProjection<Swift.UInt64>>
    public typealias Float = Primitive<NumericProjection<Swift.Float>>
    public typealias Double = Primitive<NumericProjection<Swift.Double>>
    public typealias Char = Primitive<COM.WideCharProjection>
    public typealias String = Primitive<HStringProjection>
    public typealias Guid = Primitive<COM.GUIDProjection>

    public enum Primitive<Projection: ABIProjection>: ABIProjection {
        public typealias SwiftValue = Projection.SwiftValue?
        public typealias ABIValue = UnsafeMutablePointer<CWinRTCore.SWRT_IReference>?

        public static var abiDefaultValue: ABIValue { nil }

        public static var interfaceID: COMInterfaceID {
            switch Projection.self {
                case is Bool8Projection.Type: COMInterfaceID(0x3C00FD60, 0x2950, 0x5939, 0xA21A, 0x2D12C5A01B8A)
                case is NumericProjection<Swift.UInt8>.Type: COMInterfaceID(0xE5198CC8, 0x2873, 0x55F5, 0xB0A1, 0x84FF9E4AAD62)
                case is NumericProjection<Swift.Int16>.Type: COMInterfaceID(0x6EC9E41B, 0x6709, 0x5647, 0x9918, 0xA1270110FC4E)
                case is NumericProjection<Swift.UInt16>.Type: COMInterfaceID(0x5AB7D2C3, 0x6B62, 0x5E71, 0xA4B6, 0x2D49C4F238FD)
                case is NumericProjection<Swift.Int32>.Type: COMInterfaceID(0x548CEFBD, 0xBC8A, 0x5FA0, 0x8DF2, 0x957440FC8BF4)
                case is NumericProjection<Swift.UInt32>.Type: COMInterfaceID(0x513EF3AF, 0xE784, 0x5325, 0xA91E, 0x97C2B8111CF3)
                case is NumericProjection<Swift.Int64>.Type: COMInterfaceID(0x4DDA9E24, 0xE69F, 0x5C6A, 0xA0A6, 0x93427365AF2A)
                case is NumericProjection<Swift.UInt64>.Type: COMInterfaceID(0x6755E376, 0x53BB, 0x568B, 0xA11D, 0x17239868309E)
                case is NumericProjection<Swift.Float>.Type: COMInterfaceID(0x719CC2BA, 0x3E76, 0x5DEF, 0x9F1A, 0x38D85A145EA8)
                case is NumericProjection<Swift.Double>.Type: COMInterfaceID(0x2F2D6C29, 0x5473, 0x5F3E, 0x92E7, 0x96572BB990E2)
                case is COM.WideCharProjection.Type: COMInterfaceID(0xFB393EF3, 0xBBAC, 0x5BD5, 0x9144, 0x84F23576F415)
                case is HStringProjection.Type: COMInterfaceID(0xFD416DFB, 0x2A07, 0x52EB, 0xAAE3, 0xDFCE14116C05)
                case is COM.GUIDProjection.Type: COMInterfaceID(0x7D50F649, 0x632C, 0x51F9, 0x849A, 0xEE49428933EA)
                default: fatalError("Invalid generic parameter: IReferenceProjection.Primitive<\(Projection.self)>")
            }
        }

        public static func toSwift(_ comPointer: ABIValue) -> SwiftValue {
            guard let comPointer else { return nil }
            var value: Projection.ABIValue = Projection.abiDefaultValue
            withUnsafeMutablePointer(to: &value) { valuePointer in
                try! WinRTError.throwIfFailed(comPointer.pointee.lpVtbl.pointee.get_Value(
                    comPointer, UnsafeMutableRawPointer(valuePointer)))
            }
            return Projection.toSwift(value)
        }

        public static func toABI(_ value: SwiftValue) throws -> ABIValue {
            guard let value else { return nil }

            let propertyValueStatics = try getPropertyValueStaticsNoRef()
            let virtualTable = propertyValueStatics.pointee.lpVtbl!
            var boxed: UnsafeMutablePointer<CWinRTCore.SWRT_IInspectable>? = nil
            defer { IInspectableProjection.release(&boxed) }
            try WinRTError.throwIfFailed({
                switch value {
                    case let value as Swift.Bool:
                        return virtualTable.pointee.CreateBoolean(propertyValueStatics, value, &boxed)

                    case let value as Swift.UInt8:
                        return virtualTable.pointee.CreateUInt8(propertyValueStatics, value, &boxed)

                    case let value as Swift.Int16:
                        return virtualTable.pointee.CreateInt16(propertyValueStatics, value, &boxed)

                    // UInt16 aka Unicode.UTF16.CodeUnit must be disambiguated from the projection type
                    case let value as Swift.UInt16:
                        return Projection.self == COM.WideCharProjection.self
                            ? virtualTable.pointee.CreateChar16(propertyValueStatics, value, &boxed)
                            : virtualTable.pointee.CreateUInt16(propertyValueStatics, value, &boxed)

                    case let value as Swift.Int32:
                        return virtualTable.pointee.CreateInt32(propertyValueStatics, value, &boxed)

                    case let value as Swift.UInt32:
                        return virtualTable.pointee.CreateUInt32(propertyValueStatics, value, &boxed)

                    case let value as Swift.Int64:
                        return virtualTable.pointee.CreateInt64(propertyValueStatics, value, &boxed)

                    case let value as Swift.UInt64:
                        return virtualTable.pointee.CreateUInt64(propertyValueStatics, value, &boxed)

                    case let value as Swift.Float:
                        return virtualTable.pointee.CreateSingle(propertyValueStatics, value, &boxed)

                    case let value as Swift.Double:
                        return virtualTable.pointee.CreateDouble(propertyValueStatics, value, &boxed)

                    case let value as Swift.String:
                        var abiValue = try HStringProjection.toABI(value)
                        defer { HStringProjection.release(&abiValue) }
                        return virtualTable.pointee.CreateString(propertyValueStatics, abiValue, &boxed)

                    case let value as Foundation.UUID:
                        let abiValue = COM.GUIDProjection.toABI(value)
                        return virtualTable.pointee.CreateGuid(propertyValueStatics, abiValue, &boxed)

                    default: return HResult.fail.value
                }
            }())

            guard let boxed else { throw HResult.Error.noInterface }

            return try IUnknownPointer.queryInterface(boxed, Self.interfaceID).cast(to: CWinRTCore.SWRT_IReference.self)
        }

        public static func release(_ value: inout ABIValue) {
            guard let comPointer = value else { return }
            IUnknownPointer.release(comPointer)
            value = nil
        }
    }
}