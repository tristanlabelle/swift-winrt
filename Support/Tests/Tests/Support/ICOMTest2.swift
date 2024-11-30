import COM

internal typealias ICOMTest2 = any ICOMTest2Protocol
internal protocol ICOMTest2Protocol: IUnknownProtocol {
    func comTest2() throws
}

import TestsABI

internal enum ICOMTest2Binding: COMTwoWayBinding {
    public typealias SwiftObject = ICOMTest2
    public typealias ABIStruct = TestsABI.SWRT_ICOMTest2

    public static let interfaceID = COMInterfaceID(0x5CF9DEB3, 0xD7C6, 0x42A9, 0x85B3, 0x61D8B68A7B2B)
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        Import(_wrapping: reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> ABIReference {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<ICOMTest2Binding>, ICOMTest2Protocol {
        public func comTest2() throws { try _interop.comTest2() }
    }

    private static var virtualTable: TestsABI.SWRT_ICOMTest2_VirtualTable = .init(
        QueryInterface: { IUnknownVirtualTable.QueryInterface($0, $1, $2) },
        AddRef: { IUnknownVirtualTable.AddRef($0) },
        Release: { IUnknownVirtualTable.Release($0) },
        COMTest2: { this in _implement(this) { try $0.comTest2() } })
}

public func uuidof(_: TestsABI.SWRT_ICOMTest2.Type) -> COMInterfaceID {
    ICOMTest2Binding.interfaceID
}

extension COMInterop where ABIStruct == TestsABI.SWRT_ICOMTest2 {
    public func comTest2() throws {
        try COMError.fromABI(this.pointee.VirtualTable.pointee.COMTest2(this))
    }
}
