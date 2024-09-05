import COM

public typealias IActivationFactory = any IActivationFactoryProtocol
public protocol IActivationFactoryProtocol: IInspectableProtocol {
    func activateInstance() throws -> IInspectable
}

import WindowsRuntime_ABI

public enum IActivationFactoryProjection: InterfaceProjection {
    public typealias SwiftObject = IActivationFactory
    public typealias ABIStruct = WindowsRuntime_ABI.SWRT_IActivationFactory

    public static var typeName: String { "IActivationFactory" }
    public static var interfaceID: COMInterfaceID { uuidof(ABIStruct.self) }
    public static var virtualTablePointer: UnsafeRawPointer { fatalError("Not implemented: \(#function)") }

    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        Import(_wrapping: reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> ABIReference {
        try Import.toCOM(object)
    }

    private final class Import: WinRTImport<IActivationFactoryProjection>, IActivationFactoryProtocol {
        public func activateInstance() throws -> IInspectable {
            var instancePointer = try _interop.activateInstance()
            return try NullResult.unwrap(IInspectableProjection.toSwift(consuming: &instancePointer))
        }
    }
}

public func uuidof(_: WindowsRuntime_ABI.SWRT_IActivationFactory.Type) -> COMInterfaceID {
    .init(0x00000035, 0x0000, 0x0000, 0xC000, 0x000000000046);
}

extension COMInterop where ABIStruct == WindowsRuntime_ABI.SWRT_IActivationFactory {
    // Activation factory methods are special-cased to return the pointer.
    public func activateInstance() throws -> IInspectablePointer? {
        var instance = IInspectableProjection.abiDefaultValue
        try WinRTError.fromABI(this.pointee.VirtualTable.pointee.ActivateInstance(this, &instance))
        return instance
    }

    // TODO: Move elsewhere to keep COMInterop only for bridging.
    public func activateInstance<Projection: WinRTProjection & COMProjection>(projection: Projection.Type) throws -> Projection.ABIPointer {
        var inspectable = IInspectableProjection.abiDefaultValue
        try WinRTError.fromABI(this.pointee.VirtualTable.pointee.ActivateInstance(this, &inspectable))
        defer { IInspectableProjection.release(&inspectable) }
        guard let inspectable else { throw COM.COMError.noInterface }
        return try COMInterop<IInspectableProjection.ABIStruct>(inspectable)
            .queryInterface(projection.interfaceID, type: Projection.ABIStruct.self)
            .detach()
    }
}