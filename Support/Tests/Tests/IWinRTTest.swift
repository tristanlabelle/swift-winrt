import WindowsRuntime

internal typealias IWinRTTest = any IWinRTTestProtocol
internal protocol IWinRTTestProtocol: IInspectableProtocol {
    func winRTTest() throws
}

import TestsABI

internal enum IWinRTTestBinding: InterfaceBinding {
    public typealias SwiftObject = IWinRTTest
    public typealias ABIStruct = TestsABI.SWRT_IWinRTTest

    public static var typeName: String { "IWinRTTest" }
    public static let interfaceID = COMInterfaceID(0xB6706A54, 0xCC67, 0x4090, 0x822D, 0xE165C8E36C11)
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        Import(_wrapping: reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> ABIReference {
        try Import.toCOM(object)
    }

    private final class Import: WinRTImport<IWinRTTestBinding>, IWinRTTestProtocol {
        public func winRTTest() throws { try _interop.winRTTest() }
    }

    private static var virtualTable: TestsABI.SWRT_IWinRTTest_VirtualTable = .init(
        QueryInterface: { IUnknownVirtualTable.QueryInterface($0, $1, $2) },
        AddRef: { IUnknownVirtualTable.AddRef($0) },
        Release: { IUnknownVirtualTable.Release($0) },
        GetIids: { IInspectableVirtualTable.GetIids($0, $1, $2) },
        GetRuntimeClassName: { IInspectableVirtualTable.GetRuntimeClassName($0, $1) },
        GetTrustLevel: { IInspectableVirtualTable.GetTrustLevel($0, $1) },
        WinRTTest: { this in _implement(this) { try $0.winRTTest() } })
}

public func uuidof(_: TestsABI.SWRT_IWinRTTest.Type) -> COMInterfaceID {
    IWinRTTestBinding.interfaceID
}

extension COMInterop where ABIStruct == TestsABI.SWRT_IWinRTTest {
    public func winRTTest() throws {
        try COMError.fromABI(this.pointee.VirtualTable.pointee.WinRTTest(this))
    }
}
