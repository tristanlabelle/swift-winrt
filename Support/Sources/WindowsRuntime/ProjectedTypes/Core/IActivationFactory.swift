import COM
import WindowsRuntime_ABI

public typealias IActivationFactory = any IActivationFactoryProtocol
public protocol IActivationFactoryProtocol: IInspectableProtocol {
    func activateInstance() throws -> IInspectable
}

public enum IActivationFactoryProjection: InterfaceProjection {
    public typealias SwiftObject = IActivationFactory
    public typealias COMInterface = WindowsRuntime_ABI.SWRT_IActivationFactory

    public static var typeName: String { "IActivationFactory" }
    public static var interfaceID: COMInterfaceID { COMInterface.iid }
    public static var virtualTablePointer: UnsafeRawPointer { fatalError("Not implemented: \(#function)") }

    public static func _wrap(_ reference: consuming COMReference<COMInterface>) -> SwiftObject {
        Import(_wrapping: reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMReference<COMInterface> {
        try Import.toCOM(object)
    }

    private final class Import: WinRTImport<IActivationFactoryProjection>, IActivationFactoryProtocol {
        public func activateInstance() throws -> IInspectable {
            var instancePointer = try _interop.activateInstance()
            return try NullResult.unwrap(IInspectableProjection.toSwift(consuming: &instancePointer))
        }
    }
}

#if swift(>=6)
extension SWRT_IActivationFactory: @retroactive COMIUnknownStruct {}
#endif

extension WindowsRuntime_ABI.SWRT_IActivationFactory: /* @retroactive */ COMIInspectableStruct {
    public static let iid = COMInterfaceID(0x00000035, 0x0000, 0x0000, 0xC000, 0x000000000046);
}

extension COMInterop where Interface == WindowsRuntime_ABI.SWRT_IActivationFactory {
    // Activation factory methods are special-cased to return the pointer.
    public func activateInstance() throws -> IInspectablePointer? {
        var instance = IInspectableProjection.abiDefaultValue
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.ActivateInstance(this, &instance))
        return instance
    }

    // TODO: Move elsewhere to keep COMInterop only for bridging.
    public func activateInstance<Projection: WinRTProjection & COMProjection>(projection: Projection.Type) throws -> Projection.COMPointer {
        var inspectable = IInspectableProjection.abiDefaultValue
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.ActivateInstance(this, &inspectable))
        defer { IInspectableProjection.release(&inspectable) }
        guard let inspectable else { throw COM.HResult.Error.noInterface }
        return try COMInterop<IInspectableProjection.COMInterface>(inspectable)
            .queryInterface(projection.interfaceID, type: Projection.COMInterface.self)
            .detach()
    }
}