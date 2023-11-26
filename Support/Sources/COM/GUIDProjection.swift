import CWinRTCore
import struct Foundation.UUID

/// Projects the native GUID type to Swift's Foundation.UUID type
public enum GUIDProjection: ABIInertProjection {
    public typealias SwiftValue = Foundation.UUID
    public typealias ABIValue = CWinRTCore.SWRT_Guid

    public static var abiDefaultValue: CWinRTCore.SWRT_Guid {
        .init(Data1: 0, Data2: 0, Data3: 0, Data4: (0, 0, 0, 0, 0, 0, 0, 0))
    }

    public static func toSwift(_ value: CWinRTCore.SWRT_Guid) -> Foundation.UUID {
        .init(uuid: (
            UInt8((value.Data1 >> 24) & 0xFF), UInt8((value.Data1 >> 16) & 0xFF),
            UInt8((value.Data1 >> 8) & 0xFF), UInt8((value.Data1 >> 0) & 0xFF),
            UInt8((value.Data2 >> 8) & 0xFF), UInt8((value.Data2 >> 0) & 0xFF),
            UInt8((value.Data3 >> 8) & 0xFF), UInt8((value.Data3 >> 0) & 0xFF),
            value.Data4.0, value.Data4.1, value.Data4.2, value.Data4.3, value.Data4.4, value.Data4.5, value.Data4.6, value.Data4.7
        ))
    }

    public static func toABI(_ value: Foundation.UUID) -> CWinRTCore.SWRT_Guid {
        .init(
            Data1: (UInt32(value.uuid.0) << 24) | (UInt32(value.uuid.1) << 16) | (UInt32(value.uuid.2) << 8) | UInt32(value.uuid.3),
            Data2: (UInt16(value.uuid.4) << 8) | UInt16(value.uuid.5),
            Data3: (UInt16(value.uuid.6) << 8) | UInt16(value.uuid.7),
            Data4: (value.uuid.8, value.uuid.9, value.uuid.10, value.uuid.11, value.uuid.12, value.uuid.13, value.uuid.14, value.uuid.15))
    }
}