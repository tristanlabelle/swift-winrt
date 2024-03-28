import COM
import WindowsRuntime_ABI
import struct Foundation.UUID

public enum WinRTPrimitiveProjection {
    public enum Boolean: WinRTBoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Windows.Foundation.IReference`<Boolean>" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x3C00FD60, 0x2950, 0x5939, 0xA21A, 0x2D12C5A01B8A) }
        public static var abiDefaultValue: Swift.Bool { false }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createBoolean(value))
        }
    }

    public enum UInt8: WinRTBoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Windows.Foundation.IReference`<UInt8>" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0xE5198CC8, 0x2873, 0x55F5, 0xB0A1, 0x84FF9E4AAD62) }
        public static var abiDefaultValue: Swift.UInt8 { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createUInt8(value))
        }
    }

    public enum Int16: WinRTBoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Windows.Foundation.IReference`<Int16>" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x6EC9E41B, 0x6709, 0x5647, 0x9918, 0xA1270110FC4E) }
        public static var abiDefaultValue: Swift.Int16 { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createInt16(value))
        }
    }

    public enum UInt16: WinRTBoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Windows.Foundation.IReference`<UInt16>" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x5AB7D2C3, 0x6B62, 0x5E71, 0xA4B6, 0x2D49C4F238FD) }
        public static var abiDefaultValue: Swift.UInt16 { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createUInt16(value))
        }
    }

    public enum Int32: WinRTBoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Windows.Foundation.IReference`<Int32>" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x548CEFBD, 0xBC8A, 0x5FA0, 0x8DF2, 0x957440FC8BF4) }
        public static var abiDefaultValue: Swift.Int32 { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createInt32(value))
        }
    }

    public enum UInt32: WinRTBoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Windows.Foundation.IReference`<UInt32>" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x513EF3AF, 0xE784, 0x5325, 0xA91E, 0x97C2B8111CF3) }
        public static var abiDefaultValue: Swift.UInt32 { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createUInt32(value))
        }
    }

    public enum Int64: WinRTBoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Windows.Foundation.IReference`<Int64>" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x4DDA9E24, 0xE69F, 0x5C6A, 0xA0A6, 0x93427365AF2A) }
        public static var abiDefaultValue: Swift.Int64 { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createInt64(value))
        }
    }

    public enum UInt64: WinRTBoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Windows.Foundation.IReference`<UInt64>" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x6755E376, 0x53BB, 0x568B, 0xA11D, 0x17239868309E) }
        public static var abiDefaultValue: Swift.UInt64 { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createUInt64(value))
        }
    }

    public enum Single: WinRTBoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Windows.Foundation.IReference`<Single>" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x719CC2BA, 0x3E76, 0x5DEF, 0x9F1A, 0x38D85A145EA8) }
        public static var abiDefaultValue: Swift.Float { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createSingle(value))
        }
    }

    public enum Double: WinRTBoxableProjection, ABIIdentityProjection {
        public static var typeName: Swift.String { "Windows.Foundation.IReference`<Double>" }
        public static var ireferenceID: COMInterfaceID { COMInterfaceID(0x2F2D6C29, 0x5473, 0x5F3E, 0x92E7, 0x96572BB990E2) }
        public static var abiDefaultValue: Swift.Double { 0 }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createDouble(value))
        }
    }

    public enum Char16: WinRTBoxableProjection, ABIInertProjection {
        public typealias ABIType = Swift.UInt16
        public typealias SwiftType = WindowsRuntime.Char16

        public static var typeName: Swift.String { "Windows.Foundation.IReference`<Char16>" }
        public static var ireferenceID: COM.COMInterfaceID { COMInterfaceID(0xFB393EF3, 0xBBAC, 0x5BD5, 0x9144, 0x84F23576F415) }
        public static var abiDefaultValue: ABIType { 0 }
        public static func toSwift(_ value: ABIType) -> SwiftType { .init(value) }
        public static func toABI(_ value: SwiftType) -> ABIType { value.codeUnit }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createChar16(value))
        }
    }

    public enum String: WinRTBoxableProjection {
        public typealias SwiftValue = Swift.String
        public typealias ABIValue = WindowsRuntime_ABI.SWRT_HString?

        public static var typeName: Swift.String { "Windows.Foundation.IReference`<String>" }
        public static var ireferenceID: COM.COMInterfaceID { COMInterfaceID(0xFD416DFB, 0x2A07, 0x52EB, 0xAAE3, 0xDFCE14116C05) }
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

    public enum Guid: WinRTBoxableProjection, ABIInertProjection {
        public typealias ABIType = WindowsRuntime_ABI.SWRT_Guid
        public typealias SwiftType = UUID

        public static var typeName: Swift.String { "Windows.Foundation.IReference`<Guid>" }
        public static var ireferenceID: COM.COMInterfaceID { COMInterfaceID(0x7D50F649, 0x632C, 0x51F9, 0x849A, 0xEE49428933EA) }
        public static var abiDefaultValue: ABIType { .init() }
        public static func toSwift(_ value: ABIType) -> SwiftType { COM.GUIDProjection.toSwift(value) }
        public static func toABI(_ value: SwiftType) -> ABIType { COM.GUIDProjection.toABI(value) }
        public static func box(_ value: SwiftValue) throws -> IInspectable {
            try IInspectableProjection.toSwift(PropertyValueStatics.createGuid(value))
        }
    }
}