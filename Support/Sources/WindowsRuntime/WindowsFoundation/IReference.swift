import WindowsRuntime_ABI
import struct Foundation.UUID

public typealias WindowsFoundation_IReference<T> = any WindowsFoundation_IReferenceProtocol<T>
public protocol WindowsFoundation_IReferenceProtocol<T>: WindowsFoundation_IPropertyValueProtocol {
    associatedtype T
    func _value() throws -> T
}

extension WindowsFoundation_IReferenceProtocol {
    var value: T { try! _value() }
}

public enum WindowsFoundation_IReferenceProjection<TProjection: WinRTBoxableProjection>: WinRTTwoWayProjection {
    public typealias SwiftObject = IInspectable
    public typealias COMInterface = WindowsRuntime_ABI.SWRT_WindowsFoundation_IReference
    public typealias COMVirtualTable = WindowsRuntime_ABI.SWRT_WindowsFoundation_IReferenceVTable

    public static var runtimeClassName: String { fatalError("Not implemented: \(#function)") }
    public static var interfaceID: COMInterfaceID { TProjection.ireferenceID }
    public static var virtualTablePointer: COMVirtualTablePointer { fatalError("Not implemented: \(#function)") }

    public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject {
        Import.toSwift(consume reference)
    }

    public static func toCOM(_ value: SwiftObject) throws -> COMReference<COMInterface> {
        try Import.toCOM(value)
    }

    private final class Import
            : WinRTImport<WindowsFoundation_IReferenceProjection<TProjection>>,
            WindowsFoundation_IReferenceProtocol {
        public typealias T = TProjection.SwiftValue

        public func _value() throws -> T {
            var abiValue = TProjection.abiDefaultValue
            try withUnsafeMutablePointer(to: &abiValue) { abiValuePointer in
                try _interop.get_Value(abiValuePointer)
            }
            return TProjection.toSwift(consuming: &abiValue)
        }
    }
}

#if swift(>=5.10)
extension WindowsRuntime_ABI.SWRT_WindowsFoundation_IReference: @retroactive COMIUnknownStruct {}
#endif

extension COMInterop where Interface == WindowsRuntime_ABI.SWRT_WindowsFoundation_IReference {
    public func get_Value(_ value: UnsafeMutableRawPointer) throws {
        try HResult.throwIfFailed(this.pointee.lpVtbl.pointee.get_Value(this, value))
    }
}