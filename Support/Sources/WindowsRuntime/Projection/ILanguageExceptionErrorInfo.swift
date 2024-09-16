import COM

/// Enables retrieving the IUnknown pointer stored in the error info with the call to RoOriginateLanguageException.
public typealias ILanguageExceptionErrorInfo = any ILanguageExceptionErrorInfoProtocol
public protocol ILanguageExceptionErrorInfoProtocol: IUnknownProtocol {
    var languageException: IUnknown? { get throws }
}

import WindowsRuntime_ABI

public enum ILanguageExceptionErrorInfoBinding: COMBinding {
    public typealias ABIStruct = WindowsRuntime_ABI.SWRT_ILanguageExceptionErrorInfo
    public typealias SwiftObject = ILanguageExceptionErrorInfo

    public static var interfaceID: COMInterfaceID { uuidof(ABIStruct.self) }

    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        Import(_wrapping: reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> ABIReference {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<ILanguageExceptionErrorInfoBinding>, ILanguageExceptionErrorInfoProtocol {
        var languageException: IUnknown? {
            get throws { try _interop.getLanguageException() }
        }
    }
}

public func uuidof(_: WindowsRuntime_ABI.SWRT_ILanguageExceptionErrorInfo.Type) -> COMInterfaceID {
    .init(0x04a2dbf3, 0xdf83, 0x116c, 0x0946, 0x0812abf6e07d)
}

extension COMInterop where ABIStruct == WindowsRuntime_ABI.SWRT_ILanguageExceptionErrorInfo {
    public func getLanguageException() throws -> IUnknown? {
        var result: IUnknownPointer? = nil // IUnknownBinding.abiDefaultValue (compiler bug?)
        defer { IUnknownBinding.release(&result) }
        try COMError.fromABI(this.pointee.VirtualTable.pointee.GetLanguageException(this, &result))
        return IUnknownBinding.toSwift(consuming: &result)
    }
}