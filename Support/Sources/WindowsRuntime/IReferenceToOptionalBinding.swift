import COM
import WindowsRuntime_ABI
import SWRT_WindowsFoundation

/// Binds IReference? to T? for boxable T's like primitive types, values types and delegates.
public enum IReferenceToOptionalBinding<Binding: IReferenceableBinding>: WinRTBinding, COMBinding {
    public typealias SwiftObject = Binding.SwiftValue
    public typealias ABIStruct = SWRT_WindowsFoundation_IReference

    public static var typeName: Swift.String { "Windows.Foundation.IReference`1<\(Binding.typeName)>" }
    public static var interfaceID: COMInterfaceID { Binding.ireferenceID }

    // Value types have no identity, so there's no sense unwrapping them.
    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        var abiValue = Binding.abiDefaultValue
        withUnsafeMutablePointer(to: &abiValue) { abiValuePointer in
            try! reference.interop.get_Value(abiValuePointer)
        }
        return Binding.fromABI(consuming: &abiValue)
    }

    public static func toCOM(_ value: SwiftObject) throws -> ABIReference {
        try Binding.createIReference(value)._queryInterface(interfaceID)
    }
}
