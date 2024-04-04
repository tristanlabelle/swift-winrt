import COM
import WindowsRuntime_ABI

public enum IReferenceUnboxingProjection {
    public typealias Boolean = Of<WinRTPrimitiveProjection.Boolean>
    public typealias UInt8 = Of<WinRTPrimitiveProjection.UInt8>
    public typealias Int16 = Of<WinRTPrimitiveProjection.Int16>
    public typealias UInt16 = Of<WinRTPrimitiveProjection.UInt16>
    public typealias Int32 = Of<WinRTPrimitiveProjection.Int32>
    public typealias UInt32 = Of<WinRTPrimitiveProjection.UInt32>
    public typealias Int64 = Of<WinRTPrimitiveProjection.Int64>
    public typealias UInt64 = Of<WinRTPrimitiveProjection.UInt64>
    public typealias Single = Of<WinRTPrimitiveProjection.Single>
    public typealias Double = Of<WinRTPrimitiveProjection.Double>
    public typealias Char16 = Of<WinRTPrimitiveProjection.Char16>
    public typealias String = Of<WinRTPrimitiveProjection.String>
    public typealias Guid = Of<WinRTPrimitiveProjection.Guid>

    public enum Of<Projection: WinRTBoxableProjection>: WinRTProjection, COMProjection {
        public typealias SwiftObject = Projection.SwiftValue
        public typealias COMInterface = WindowsRuntime_ABI.SWRT_WindowsFoundation_IReference

        public static var typeName: Swift.String { "Windows.Foundation.IReference`1<\(Projection.typeName)>" }
        public static var interfaceID: COMInterfaceID { Projection.ireferenceID }

        // Value types have no identity, so there's no sense unwrapping them.
        public static func _wrap(_ reference: consuming COMReference<COMInterface>) -> SwiftObject {
            var abiValue = Projection.abiDefaultValue
            withUnsafeMutablePointer(to: &abiValue) { abiValuePointer in
                _ = try! HResult.throwIfFailed(reference.pointer.pointee.VirtualTable.pointee.get_Value(
                    reference.pointer, abiValuePointer))
            }
            return Projection.toSwift(consuming: &abiValue)
        }

        public static func toCOM(_ value: SwiftObject) throws -> COMReference<COMInterface> {
            try Projection.box(value)._queryInterface(interfaceID).reinterpret()
        }
    }
}
