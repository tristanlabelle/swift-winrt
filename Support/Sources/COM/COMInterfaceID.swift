import struct Foundation.UUID

public typealias COMInterfaceID = Foundation.UUID

extension COMInterfaceID {
    // Initializer supporting a GUID-like syntax: .init(0x00000000, 0x0000, 0x0000, 0xC000, 0x000000000046)
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
}