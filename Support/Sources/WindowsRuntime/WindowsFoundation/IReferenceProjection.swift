import COM
import WindowsRuntime_ABI
import struct Foundation.UUID

public enum WindowsFoundation_IReferenceProjection {
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

    public enum Of<UnboxedProjection: WinRTBoxableProjection>: COMProjection {
        public typealias SwiftObject = UnboxedProjection.SwiftValue
        public typealias COMInterface = WindowsRuntime_ABI.SWRT_WindowsFoundation_IReference
        public typealias COMVirtualTable = WindowsRuntime_ABI.SWRT_WindowsFoundation_IReferenceVTable

        public static var interfaceID: COMInterfaceID { UnboxedProjection.ireferenceID }

        public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject {
            var abiValue = UnboxedProjection.abiDefaultValue
            withUnsafeMutablePointer(to: &abiValue) { abiValuePointer in
                _ = try! HResult.throwIfFailed(reference.pointer.pointee.lpVtbl.pointee.get_Value(
                    reference.pointer, abiValuePointer))
            }
            return UnboxedProjection.toSwift(consuming: &abiValue)
        }

        public static func toCOM(_ value: SwiftObject) throws -> COMReference<COMInterface> {
            try UnboxedProjection.box(value)._queryInterface(interfaceID).reinterpret()
        }

        public static func release(_ value: inout ABIValue) {
            guard let comPointer = value else { return }
            COMInterop(comPointer).release()
            value = nil
        }
    }
}
