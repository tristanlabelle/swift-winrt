import WindowsRuntime_ABI

public typealias ILanguageExceptionErrorInfo = any ILanguageExceptionErrorInfoProtocol
public protocol ILanguageExceptionErrorInfoProtocol: IUnknownProtocol {
    var languageException: IUnknown { get throws }
}

public enum ILanguageExceptionErrorInfoProjection: COMTwoWayProjection {
    public typealias ABIStruct = WindowsRuntime_ABI.SWRT_ILanguageExceptionErrorInfo
    public typealias SwiftObject = ILanguageExceptionErrorInfo

    public static var interfaceID: COMInterfaceID { uuidof(ABIStruct.self) }
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        Import(_wrapping: reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> ABIReference {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<ILanguageExceptionErrorInfoProjection>, ILanguageExceptionErrorInfoProtocol {
        var languageException: IUnknown {
            get throws { try NullResult.unwrap(_interop.getLanguageException()) }
        }
    }

    private static var virtualTable: WindowsRuntime_ABI.SWRT_ILanguageExceptionErrorInfo_VirtualTable = .init(
        QueryInterface: { IUnknownVirtualTable.QueryInterface($0, $1, $2) },
        AddRef: { IUnknownVirtualTable.AddRef($0) },
        Release: { IUnknownVirtualTable.Release($0) },
        GetLanguageException: { this, languageException in _implement(this) {
            TODO;
        } })
}

public func uuidof(_: WindowsRuntime_ABI.SWRT_ILanguageExceptionErrorInfo.Type) -> COMInterfaceID {
    .init(TODO)
}

extension COMInterop where ABIStruct == WindowsRuntime_ABI.SWRT_ILanguageExceptionErrorInfo {
    public func getLanguageException() throws -> IUnkown {
        var result: IUnknownProjection.abiDefaultValue
        defer { IUnknownProjection.release(&result) }
        try COMError.fromABI(this.pointee.VirtualTable.pointee.GetLanguageException(this, &result))
        return try NullResult.unwrap(IUnknownProjection.toSwift(consuming: &result))
    }
}