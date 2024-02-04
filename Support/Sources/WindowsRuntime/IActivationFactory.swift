import CWinRTCore

public protocol IActivationFactoryProtocol: IInspectableProtocol {
    func activateInstance() throws -> IInspectable
}

public typealias IActivationFactory = any IActivationFactoryProtocol

public enum IActivationFactoryProjection: WinRTProjection {
    public typealias SwiftObject = IActivationFactory
    public typealias COMInterface = CWinRTCore.SWRT_IActivationFactory
    public typealias COMVirtualTable = CWinRTCore.SWRT_IActivationFactoryVTable

    public static let id = COMInterfaceID(0x00000035, 0x0000, 0x0000, 0xC000, 0x000000000046);
    public static var runtimeClassName: String { "IActivationFactory" }

    public static func toSwift(transferringRef comPointer: COMPointer) -> SwiftObject {
        toSwift(transferringRef: comPointer, importType: Import.self)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMPointer {
        try toCOM(object, importType: Import.self)
    }

    private final class Import: WinRTImport<IActivationFactoryProjection>, IActivationFactoryProtocol {
        public func activateInstance() throws -> IInspectable {
            try NullResult.unwrap(_interop.activateInstance())
        }
    }
}

extension CWinRTCore.SWRT_IActivationFactory: /* @retroactive */ COMIInspectableStruct {}

extension COMInterop where Interface == CWinRTCore.SWRT_IActivationFactory {
    public func activateInstance() throws -> IInspectable? {
        var instance = IInspectableProjection.abiDefaultValue
        try WinRTError.throwIfFailed(_pointer.pointee.lpVtbl.pointee.ActivateInstance(_pointer, &instance))
        return IInspectableProjection.toSwift(consuming: &instance)
    }
}