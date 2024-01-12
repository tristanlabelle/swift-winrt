import struct Foundation.UUID

public typealias COMInterfaceID = Foundation.UUID

extension COMInterfaceID {
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