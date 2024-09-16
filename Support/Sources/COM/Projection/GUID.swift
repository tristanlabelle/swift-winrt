import COM_ABI
import struct Foundation.UUID

public typealias GUID = Foundation.UUID

extension GUID {
    /// Initializer supporting a GUID-like syntax: .init(0x00000000, 0x0000, 0x0000, 0xC000, 0x000000000046)
    public init(_ data1: UInt32, _ data2: UInt16, _ data3: UInt16, _ data4: UInt16, _ data5: UInt64) {
        precondition(data5 < 0x1_00_00_00_00_00_00)
        let bytes = (
            UInt8((data1 >> 24) & 0xFF), UInt8((data1 >> 16) & 0xFF), UInt8((data1 >> 8) & 0xFF), UInt8((data1 >> 0) & 0xFF),
            UInt8((data2 >> 8) & 0xFF), UInt8((data2 >> 0) & 0xFF),
            UInt8((data3 >> 8) & 0xFF), UInt8((data3 >> 0) & 0xFF),
            UInt8((data4 >> 8) & 0xFF), UInt8((data4 >> 0) & 0xFF),
            UInt8((data5 >> 40) & 0xFF), UInt8((data5 >> 32) & 0xFF),
            UInt8((data5 >> 24) & 0xFF), UInt8((data5 >> 16) & 0xFF),
            UInt8((data5 >> 8) & 0xFF), UInt8((data5 >> 0) & 0xFF))
        self.init(uuid: bytes)
    }

    /// Initializer for copying out of ILSpy
    /// [Windows.Foundation.Metadata.Guid(2908547984u, 62745, 22786, 149, 48, 215, 242, 47, 226, 221, 132)]
    public init(
            _ data1: UInt32, _ data2: UInt16, _ data3: UInt16,
            _ data4: UInt8, _ data5: UInt8, _ data6: UInt8, _ data7: UInt8,
            _ data8: UInt8, _ data9: UInt8, _ data10: UInt8, _ data11: UInt8) {
        let bytes = (
            UInt8((data1 >> 24) & 0xFF), UInt8((data1 >> 16) & 0xFF), UInt8((data1 >> 8) & 0xFF), UInt8((data1 >> 0) & 0xFF),
            UInt8((data2 >> 8) & 0xFF), UInt8((data2 >> 0) & 0xFF),
            UInt8((data3 >> 8) & 0xFF), UInt8((data3 >> 0) & 0xFF),
            data4, data5, data6, data7, data8, data9, data10, data11)
        self.init(uuid: bytes)
    }
}

/// Binds the native GUID type to Swift's Foundation.UUID type
public enum GUIDBinding: PODBinding {
    public typealias SwiftValue = GUID
    public typealias ABIValue = COM_ABI.SWRT_Guid

    public static var abiDefaultValue: COM_ABI.SWRT_Guid {
        .init(Data1: 0, Data2: 0, Data3: 0, Data4: (0, 0, 0, 0, 0, 0, 0, 0))
    }

    public static func fromABI(_ value: COM_ABI.SWRT_Guid) -> GUID {
        .init(uuid: (
            UInt8((value.Data1 >> 24) & 0xFF), UInt8((value.Data1 >> 16) & 0xFF),
            UInt8((value.Data1 >> 8) & 0xFF), UInt8((value.Data1 >> 0) & 0xFF),
            UInt8((value.Data2 >> 8) & 0xFF), UInt8((value.Data2 >> 0) & 0xFF),
            UInt8((value.Data3 >> 8) & 0xFF), UInt8((value.Data3 >> 0) & 0xFF),
            value.Data4.0, value.Data4.1, value.Data4.2, value.Data4.3, value.Data4.4, value.Data4.5, value.Data4.6, value.Data4.7
        ))
    }

    public static func toABI(_ value: GUID) -> COM_ABI.SWRT_Guid {
        .init(
            Data1: (UInt32(value.uuid.0) << 24) | (UInt32(value.uuid.1) << 16) | (UInt32(value.uuid.2) << 8) | UInt32(value.uuid.3),
            Data2: (UInt16(value.uuid.4) << 8) | UInt16(value.uuid.5),
            Data3: (UInt16(value.uuid.6) << 8) | UInt16(value.uuid.7),
            Data4: (value.uuid.8, value.uuid.9, value.uuid.10, value.uuid.11, value.uuid.12, value.uuid.13, value.uuid.14, value.uuid.15))
    }
}