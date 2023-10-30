import CWinRTCore

public typealias IID = CWinRTCore.IID

extension IID {
    public init(_ data1: UInt32, _ data2: UInt16, _ data3: UInt16, _ data4: UInt16, _ data5: UInt64) {
        precondition(data5 < 0x1_00_00_00_00_00_00)
        self.init(Data1: data1, Data2: data2, Data3: data3, Data4: (
            UInt8((data4 >> 8) & 0xFF), UInt8((data4 >> 0) & 0xFF),
            UInt8((data5 >> 40) & 0xFF), UInt8((data5 >> 32) & 0xFF),
            UInt8((data5 >> 24) & 0xFF), UInt8((data5 >> 16) & 0xFF),
            UInt8((data5 >> 8) & 0xFF), UInt8((data5 >> 0) & 0xFF)))
    }
}

extension IID: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.Data1 == rhs.Data1 && lhs.Data2 == rhs.Data2 && lhs.Data3 == rhs.Data3
            && lhs.Data4.0 == rhs.Data4.0 && lhs.Data4.1 == rhs.Data4.1
            && lhs.Data4.2 == rhs.Data4.2 && lhs.Data4.3 == rhs.Data4.3
            && lhs.Data4.4 == rhs.Data4.4 && lhs.Data4.5 == rhs.Data4.5
            && lhs.Data4.6 == rhs.Data4.6 && lhs.Data4.7 == rhs.Data4.7
    }
}