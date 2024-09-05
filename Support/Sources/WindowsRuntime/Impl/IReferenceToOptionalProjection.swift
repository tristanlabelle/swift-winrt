import COM
import WindowsRuntime_ABI
import SWRT_WindowsFoundation

/// Provides projections from IReference? to T? for boxable T's like primitive types, values types and delegates.
public enum IReferenceToOptionalProjection<Projection: IReferenceableProjection>: WinRTProjection, COMProjection {
    public typealias SwiftObject = Projection.SwiftValue
    public typealias ABIStruct = SWRT_WindowsFoundation_IReference

    public static var typeName: Swift.String { "Windows.Foundation.IReference`1<\(Projection.typeName)>" }
    public static var interfaceID: COMInterfaceID { Projection.ireferenceID }

    // Value types have no identity, so there's no sense unwrapping them.
    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        var abiValue = Projection.abiDefaultValue
        withUnsafeMutablePointer(to: &abiValue) { abiValuePointer in
            try! reference.interop.get_Value(abiValuePointer)
        }
        return Projection.toSwift(consuming: &abiValue)
    }

    public static func toCOM(_ value: SwiftObject) throws -> ABIReference {
        try Projection.createIReference(value)._queryInterface(interfaceID)
    }
}
