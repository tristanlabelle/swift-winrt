import COM

internal typealias ICOMTest = any ICOMTestProtocol
internal protocol ICOMTestProtocol: IUnknownProtocol {
    func comTest() throws
}

import TestsABI

internal enum ICOMTestBinding: COMTwoWayBinding {
    public typealias SwiftObject = ICOMTest
    public typealias ABIStruct = SWRT_ICOMTest

    public static var interfaceID: COMInterfaceID { uuidof(ABIStruct.self) }
    public static var exportedVirtualTable: VirtualTablePointer { .init(&virtualTable) }

    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        Import(_wrapping: reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> ABIReference {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<ICOMTestBinding>, ICOMTestProtocol {
        public func comTest() throws { try _interop.comTest() }
    }

    private static var virtualTable: SWRT_ICOMTest_VirtualTable = .init(
        QueryInterface: { IUnknownVirtualTable.QueryInterface($0, $1, $2) },
        AddRef: { IUnknownVirtualTable.AddRef($0) },
        Release: { IUnknownVirtualTable.Release($0) },
        COMTest: { this in _implement(this) { try $0.comTest() } })
}

public func uuidof(_: SWRT_ICOMTest.Type) -> COMInterfaceID {
    .init(0x5CF9DEB3, 0xD7C6, 0x42A9, 0x85B3, 0x61D8B68A7B2A)
}

extension COMInterop where ABIStruct == SWRT_ICOMTest {
    public func comTest() throws {
        try COMError.fromABI(this.pointee.VirtualTable.pointee.COMTest(this))
    }
}
