import COM
import WindowsRuntime_ABI

public enum PrimitiveProjection {
    public enum Boolean: BoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Windows.Foundation.IReference`<Boolean>" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x3C00FD60, 0x2950, 0x5939, 0xA21A, 0x2D12C5A01B8A) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0x3F8A51CE, 0x4EFD, 0x5252, 0xBCE7, 0x86C498B20598) }
        public static var abiDefaultValue: CBool { false }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createBoolean(value))
        }
        public static func boxArray(_ value: [SwiftValue]) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createBooleanArray(value))
        }
    }

    public enum UInt8: BoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Windows.Foundation.IReference`<UInt8>" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0xE5198CC8, 0x2873, 0x55F5, 0xB0A1, 0x84FF9E4AAD62) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0x98B5C88B, 0x9C06, 0x501C, 0x8BA8, 0xC356F8159B3C) }
        public static var abiDefaultValue: Swift.UInt8 { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createUInt8(value))
        }
        public static func boxArray(_ value: [SwiftValue]) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createUInt8Array(value))
        }
    }

    public enum Int16: BoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Windows.Foundation.IReference`<Int16>" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x6EC9E41B, 0x6709, 0x5647, 0x9918, 0xA1270110FC4E) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0x57E8AEC5, 0xA4EF, 0x557A, 0xA4F0, 0x37A1C5763C88) }
        public static var abiDefaultValue: Swift.Int16 { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createInt16(value))
        }
        public static func boxArray(_ value: [SwiftValue]) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createInt16Array(value))
        }
    }

    public enum UInt16: BoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Windows.Foundation.IReference`<UInt16>" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x5AB7D2C3, 0x6B62, 0x5E71, 0xA4B6, 0x2D49C4F238FD) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0x6937D62E, 0xC385, 0x53ED, 0xBA45, 0xA4EDACBA8FDA) }
        public static var abiDefaultValue: Swift.UInt16 { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createUInt16(value))
        }
        public static func boxArray(_ value: [SwiftValue]) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createUInt16Array(value))
        }
    }

    public enum Int32: BoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Windows.Foundation.IReference`<Int32>" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x548CEFBD, 0xBC8A, 0x5FA0, 0x8DF2, 0x957440FC8BF4) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0xB39737FC, 0x7B89, 0x5837, 0x9DB9, 0x3222BF19C4E2) }
        public static var abiDefaultValue: Swift.Int32 { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createInt32(value))
        }
        public static func boxArray(_ value: [SwiftValue]) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createInt32Array(value))
        }
    }

    public enum UInt32: BoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Windows.Foundation.IReference`<UInt32>" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x513EF3AF, 0xE784, 0x5325, 0xA91E, 0x97C2B8111CF3) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0x259C6843, 0x7201, 0x5DA1, 0x8F4C, 0x211D55B341D7) }
        public static var abiDefaultValue: Swift.UInt32 { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createUInt32(value))
        }
        public static func boxArray(_ value: [SwiftValue]) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createUInt32Array(value))
        }
    }

    public enum Int64: BoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Windows.Foundation.IReference`<Int64>" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x4DDA9E24, 0xE69F, 0x5C6A, 0xA0A6, 0x93427365AF2A) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0x0638676B, 0x18D9, 0x5A6E, 0x9A43, 0xC0D08762E64E) }
        public static var abiDefaultValue: Swift.Int64 { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createInt64(value))
        }
        public static func boxArray(_ value: [SwiftValue]) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createInt64Array(value))
        }
    }

    public enum UInt64: BoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Windows.Foundation.IReference`<UInt64>" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x6755E376, 0x53BB, 0x568B, 0xA11D, 0x17239868309E) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0x8C1C73A0, 0x3BDE, 0x5671, 0xA677, 0xAB3131B7A741) }
        public static var abiDefaultValue: Swift.UInt64 { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createUInt64(value))
        }
        public static func boxArray(_ value: [SwiftValue]) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createUInt64Array(value))
        }
    }

    public enum Single: BoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Windows.Foundation.IReference`<Single>" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x719CC2BA, 0x3E76, 0x5DEF, 0x9F1A, 0x38D85A145EA8) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0x47518C1F, 0xBE4F, 0x5A72, 0xBC19, 0xBB5BF8E2394E) }
        public static var abiDefaultValue: CFloat { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createSingle(value))
        }
        public static func boxArray(_ value: [SwiftValue]) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createSingleArray(value))
        }
    }

    public enum Double: BoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Windows.Foundation.IReference`<Double>" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x2F2D6C29, 0x5473, 0x5F3E, 0x92E7, 0x96572BB990E2) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0xFF8F7AA1, 0xB98E, 0x557B, 0xBFEA, 0x06CAE1C07FA3) }
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

        public static var typeName: Swift.String { "Windows.Foundation.IReference`<Char16>" }
        public static var ireferenceID: COM.COMInterfaceID { COMInterfaceID(0xFB393EF3, 0xBBAC, 0x5BD5, 0x9144, 0x84F23576F415) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0x7E609D6F, 0xAECB, 0x5108, 0xAFCB, 0xC29BB3323276) }
        public static var abiDefaultValue: ABIType { 0 }
        public static func toSwift(_ value: ABIType) -> SwiftType { .init(value) }
        public static func toABI(_ value: SwiftType) -> ABIType { value.codeUnit }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createChar16(value))
        }
    }

    public enum String: BoxableProjection {
        public typealias SwiftValue = Swift.String
        public typealias ABIValue = WindowsRuntime_ABI.SWRT_HString?

        public static var typeName: Swift.String { "Windows.Foundation.IReference`<String>" }
        public static var ireferenceID: COM.COMInterfaceID { COMInterfaceID(0xFD416DFB, 0x2A07, 0x52EB, 0xAAE3, 0xDFCE14116C05) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0x214163EB, 0xBD7D, 0x50B0, 0x99C7, 0x56C1F5612A5B) }
        public static var abiDefaultValue: ABIValue { nil }

        public static func toSwift(_ value: ABIValue) -> SwiftValue {
            HString.toString(value)
        }

        public static func toABI(_ value: SwiftValue) throws -> ABIValue {
            try HString.create(value).detach()
        }

        public static func release(_ value: inout ABIValue) {
            HString.delete(value)
            value = nil
        }

        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createString(value))
        }
    }

    public enum Guid: BoxableProjection, ABIInertProjection {
        public typealias ABIType = WindowsRuntime_ABI.SWRT_Guid
        public typealias SwiftType = GUID

        public static var typeName: Swift.String { "Windows.Foundation.IReference`<Guid>" }
        public static var ireferenceID: COM.COMInterfaceID { COMInterfaceID(0x7D50F649, 0x632C, 0x51F9, 0x849A, 0xEE49428933EA) }
        public static var ireferenceArrayID: COMInterfaceID { COMInterfaceID(0x1662923F, 0x5579, 0x5B8E, 0xB981, 0xE57EC9CA4240) }
        public static var abiDefaultValue: ABIType { .init() }
        public static func toSwift(_ value: ABIType) -> SwiftType { COM.GUIDProjection.toSwift(value) }
        public static func toABI(_ value: SwiftType) -> ABIType { COM.GUIDProjection.toABI(value) }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createGuid(value))
        }
    }
}