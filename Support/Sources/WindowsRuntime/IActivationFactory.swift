import CWinRTCore

public protocol IActivationFactoryProtocol: IInspectableProtocol {
    func activateInstance() throws -> IInspectable
}

public typealias IActivationFactory = any IActivationFactoryProtocol

public enum IActivationFactoryProjection: WinRTProjection {
    public typealias SwiftObject = IActivationFactory
    public typealias COMInterface = CWinRTCore.SWRT_IActivationFactory
    public typealias COMVirtualTable = CWinRTCore.SWRT_IActivationFactoryVTable

    public static var id: COMInterfaceID { COMInterop<COMInterface>.iid }
    public static var runtimeClassName: String { "IActivationFactory" }

    public static func toSwift(transferringRef comPointer: COMPointer) -> SwiftObject {
        Import.toSwift(transferringRef: comPointer)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMPointer {
        try Import.toCOM(object)
    }

    private final class Import: WinRTImport<IActivationFactoryProjection>, IActivationFactoryProtocol {
        public func activateInstance() throws -> IInspectable {
            var instancePointer = try _interop.activateInstance()
            return try NullResult.unwrap(IInspectableProjection.toSwift(consuming: &instancePointer))
        }
    }
}

extension CWinRTCore.SWRT_IActivationFactory: /* @retroactive */ COMIInspectableStruct {}

extension COMInterop where Interface == CWinRTCore.SWRT_IActivationFactory {
    public static let iid = COMInterfaceID(0x00000035, 0x0000, 0x0000, 0xC000, 0x000000000046);

    // Activation factory methods are special-cased to return the pointer.
    public func activateInstance() throws -> IInspectablePointer? {
        var instance = IInspectableProjection.abiDefaultValue
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.ActivateInstance(this, &instance))
        return instance
    }

    // TODO: Move elsewhere to keep COMInterop only for bridging.
    public func activateInstance<Projection: WinRTProjection>(projection: Projection.Type) throws -> Projection.COMPointer {
        var inspectable = IInspectableProjection.abiDefaultValue
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.ActivateInstance(this, &inspectable))
        defer { IInspectableProjection.release(&inspectable) }
        guard let inspectable else { throw COM.HResult.Error.noInterface }
        return try COMInterop<IInspectableProjection.COMInterface>(inspectable)
            .queryInterface(projection.id).cast(to: Projection.COMInterface.self)
    }
}