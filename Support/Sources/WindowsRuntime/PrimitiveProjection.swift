import COM
import WindowsRuntime_ABI

public enum PrimitiveProjection {
    public enum Boolean: BoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Boolean" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x3C00FD60, 0x2950, 0x5939, 0xA21A, 0x2D12C5A01B8A) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0xE8E72666, 0x48CC, 0x593F, 0xBA85, 0x2663496956E3) }
        public static var abiDefaultValue: CBool { false }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createBoolean(value))
        }
        public static func boxArray(_ value: [SwiftValue]) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createBooleanArray(value))
        }
    }

    public enum UInt8: BoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "UInt8" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0xE5198CC8, 0x2873, 0x55F5, 0xB0A1, 0x84FF9E4AAD62) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0x2AF22683, 0x3734, 0x56D0, 0xA60E, 0x688CC85D1619) }
        public static var abiDefaultValue: Swift.UInt8 { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createUInt8(value))
        }
        public static func boxArray(_ value: [SwiftValue]) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createUInt8Array(value))
        }
    }

    public enum Int16: BoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Int16" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x6EC9E41B, 0x6709, 0x5647, 0x9918, 0xA1270110FC4E) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0x912F8FD7, 0xADC0, 0x5D60, 0xA896, 0x7ED76089CC5B) }
        public static var abiDefaultValue: Swift.Int16 { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createInt16(value))
        }
        public static func boxArray(_ value: [SwiftValue]) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createInt16Array(value))
        }
    }

    public enum UInt16: BoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "UInt16" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x5AB7D2C3, 0x6B62, 0x5E71, 0xA4B6, 0x2D49C4F238FD) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0x6624A2DD, 0x83F7, 0x519C, 0x9D55, 0xBB1F6560456B) }
        public static var abiDefaultValue: Swift.UInt16 { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createUInt16(value))
        }
        public static func boxArray(_ value: [SwiftValue]) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createUInt16Array(value))
        }
    }

    public enum Int32: BoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Int32" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x548CEFBD, 0xBC8A, 0x5FA0, 0x8DF2, 0x957440FC8BF4) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0xA6D080A5, 0xB087, 0x5BC2, 0x9A9F, 0x5CD687B4D1F7) }
        public static var abiDefaultValue: Swift.Int32 { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createInt32(value))
        }
        public static func boxArray(_ value: [SwiftValue]) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createInt32Array(value))
        }
    }

    public enum UInt32: BoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "UInt32" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x513EF3AF, 0xE784, 0x5325, 0xA91E, 0x97C2B8111CF3) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0x97374B68, 0xEB87, 0x56CC, 0xB18E, 0x27EF0F9CFC0C) }
        public static var abiDefaultValue: Swift.UInt32 { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createUInt32(value))
        }
        public static func boxArray(_ value: [SwiftValue]) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createUInt32Array(value))
        }
    }

    public enum Int64: BoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Int64" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x4DDA9E24, 0xE69F, 0x5C6A, 0xA0A6, 0x93427365AF2A) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0x6E333271, 0x2E2A, 0x5955, 0x8790, 0x836C76EE53B6) }
        public static var abiDefaultValue: Swift.Int64 { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createInt64(value))
        }
        public static func boxArray(_ value: [SwiftValue]) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createInt64Array(value))
        }
    }

    public enum UInt64: BoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "UInt64" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x6755E376, 0x53BB, 0x568B, 0xA11D, 0x17239868309E) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0x38B60434, 0xD67C, 0x523E, 0x9D0E, 0x24D643411073) }
        public static var abiDefaultValue: Swift.UInt64 { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createUInt64(value))
        }
        public static func boxArray(_ value: [SwiftValue]) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createUInt64Array(value))
        }
    }

    public enum Single: BoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Single" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x719CC2BA, 0x3E76, 0x5DEF, 0x9F1A, 0x38D85A145EA8) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0x6AB1EA83, 0xCB41, 0x5F99, 0x92CC, 0x23BD4336A1FB) }
        public static var abiDefaultValue: CFloat { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createSingle(value))
        }
        public static func boxArray(_ value: [SwiftValue]) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createSingleArray(value))
        }
    }

    public enum Double: BoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Double" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x2F2D6C29, 0x5473, 0x5F3E, 0x92E7, 0x96572BB990E2) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0xD301F253, 0xE0A3, 0x5D2B, 0x9A41, 0xA4D62BEC4623) }
        public static var abiDefaultValue: CDouble { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createDouble(value))
        }
        public static func boxArray(_ value: [SwiftValue]) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createDoubleArray(value))
        }
    }

    public enum Char16: BoxableProjection, ABIInertProjection {
        public typealias ABIType = Swift.UInt16
        public typealias SwiftType = WindowsRuntime.Char16

        public static var typeName: Swift.String { "Char16" }
        public static var ireferenceID: COM.COMInterfaceID { COMInterfaceID(0xFB393EF3, 0xBBAC, 0x5BD5, 0x9144, 0x84F23576F415) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0xA4095AAB, 0xEB7D, 0x5782, 0x8FAD, 0x1609DEA249AD) }
        public static var abiDefaultValue: ABIType { 0 }
        public static func toSwift(_ value: ABIType) -> SwiftType { .init(value) }
        public static func toABI(_ value: SwiftType) -> ABIType { value.codeUnit }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createChar16(value))
        }
        public static func boxArray(_ value: [SwiftValue]) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createChar16Array(value))
        }
    }

    public enum String: BoxableProjection {
        public typealias SwiftValue = Swift.String
        public typealias ABIValue = WindowsRuntime_ABI.SWRT_HString?

        public static var typeName: Swift.String { "String" }
        public static var ireferenceID: COM.COMInterfaceID { COMInterfaceID(0xFD416DFB, 0x2A07, 0x52EB, 0xAAE3, 0xDFCE14116C05) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0x0385688E, 0xE3C7, 0x5C5E, 0xA389, 0x5524EDE349F1) }
        public static var abiDefaultValue: ABIValue { nil }

        public static func toSwift(_ value: ABIValue) -> SwiftValue { HString.toString(value) }
        public static func toABI(_ value: SwiftValue) throws -> ABIValue { try HString.create(value).detach() }

        public static func release(_ value: inout ABIValue) {
            HString.delete(value)
            value = nil
        }

        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createString(value))
        }

        public static func boxArray(_ value: [SwiftValue]) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createStringArray(value))
        }
    }

    public enum Guid: BoxableProjection, ABIInertProjection {
        public typealias ABIType = WindowsRuntime_ABI.SWRT_Guid
        public typealias SwiftType = GUID

        public static var typeName: Swift.String { "Guid" }
        public static var ireferenceID: COM.COMInterfaceID { COMInterfaceID(0x7D50F649, 0x632C, 0x51F9, 0x849A, 0xEE49428933EA) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0xEECF9838, 0xC1C2, 0x5B4A, 0x976F, 0xCEC261AE1D55) }
        public static var abiDefaultValue: ABIType { .init() }
        public static func toSwift(_ value: ABIType) -> SwiftType { COM.GUIDProjection.toSwift(value) }
        public static func toABI(_ value: SwiftType) -> ABIType { COM.GUIDProjection.toABI(value) }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createGuid(value))
        }
        public static func boxArray(_ value: [SwiftValue]) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createGuidArray(value))
        }
    }
}