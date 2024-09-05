import COM

/// Enables language projections to provide and retrieve error information as with ILanguageExceptionErrorInfo,
/// with the additional benefit of working across language boundaries.
public typealias ILanguageExceptionErrorInfo2 = any ILanguageExceptionErrorInfo2Protocol
public protocol ILanguageExceptionErrorInfo2Protocol: ILanguageExceptionErrorInfoProtocol {
    var previousLanguageExceptionErrorInfo: ILanguageExceptionErrorInfo2? { get throws }
    func capturePropagationContext(_ languageException: IUnknown?) throws
    var propagationContextHead: ILanguageExceptionErrorInfo2? { get throws }
}

import WindowsRuntime_ABI

public enum ILanguageExceptionErrorInfo2Projection: COMProjection {
    public typealias ABIStruct = WindowsRuntime_ABI.SWRT_ILanguageExceptionErrorInfo2
    public typealias SwiftObject = ILanguageExceptionErrorInfo2

    public static var interfaceID: COMInterfaceID { uuidof(ABIStruct.self) }

    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        Import(_wrapping: reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> ABIReference {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<ILanguageExceptionErrorInfo2Projection>, ILanguageExceptionErrorInfo2Protocol {
        var languageException: IUnknown? {
            get throws { try _interop.getLanguageException() }
        }

        var previousLanguageExceptionErrorInfo: ILanguageExceptionErrorInfo2? {
            get throws { try _interop.getPreviousLanguageExceptionErrorInfo() }
        }

        func capturePropagationContext(_ languageException: IUnknown?) throws {
            try _interop.capturePropagationContext(languageException)
        }

        var propagationContextHead: ILanguageExceptionErrorInfo2? {
            get throws { try _interop.getPropagationContextHead() }
        }
    }
}

public func uuidof(_: WindowsRuntime_ABI.SWRT_ILanguageExceptionErrorInfo2.Type) -> COMInterfaceID {
    .init(0x5746E5C4, 0x5B97, 0x424C, 0xB620, 0x2822915734DD)
}

extension COMInterop where ABIStruct == WindowsRuntime_ABI.SWRT_ILanguageExceptionErrorInfo2 {
    public func getLanguageException() throws -> IUnknown? {
        var result: IUnknownPointer? = nil // IUnknownProjection.abiDefaultValue (compiler bug?)
        defer { IUnknownProjection.release(&result) }
        try COMError.fromABI(this.pointee.VirtualTable.pointee.GetLanguageException(this, &result))
        return IUnknownProjection.toSwift(consuming: &result)
    }

    public func getPreviousLanguageExceptionErrorInfo() throws -> ILanguageExceptionErrorInfo2? {
        var result = ILanguageExceptionErrorInfo2Projection.abiDefaultValue
        defer { ILanguageExceptionErrorInfo2Projection.release(&result) }
        try COMError.fromABI(this.pointee.VirtualTable.pointee.GetPreviousLanguageExceptionErrorInfo(this, &result))
        return ILanguageExceptionErrorInfo2Projection.toSwift(consuming: &result)
    }

    public func capturePropagationContext(_ languageException: IUnknown?) throws {
        var languageException = try IUnknownProjection.toABI(languageException)
        defer { IUnknownProjection.release(&languageException) }
        try COMError.fromABI(this.pointee.VirtualTable.pointee.CapturePropagationContext(this, languageException))
    }

    public func getPropagationContextHead() throws -> ILanguageExceptionErrorInfo2? {
        var result = ILanguageExceptionErrorInfo2Projection.abiDefaultValue
        defer { ILanguageExceptionErrorInfo2Projection.release(&result) }
        try COMError.fromABI(this.pointee.VirtualTable.pointee.GetPropagationContextHead(this, &result))
        return ILanguageExceptionErrorInfo2Projection.toSwift(consuming: &result)
    }
}