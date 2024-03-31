import WindowsRuntime_ABI
import struct Foundation.UUID

/// Enables arbitrary enumerations, structures, and delegate types to be used as property values.
public typealias WindowsFoundation_IReference<T> = any WindowsFoundation_IReferenceProtocol<T>

/// Allows nongeneric uses of the IReference protocol.
public protocol WindowsFoundation_IReferenceProtocolABI {
    func _getABIValue(_ pointer: UnsafeMutableRawPointer) throws
}

/// Enables arbitrary enumerations, structures, and delegate types to be used as property values.
public protocol WindowsFoundation_IReferenceProtocol<T>: WindowsFoundation_IPropertyValueProtocol, WindowsFoundation_IReferenceProtocolABI {
    associatedtype T

    /// Gets the type that is represented as an IPropertyValue.
    func _value() throws -> T
}

extension WindowsFoundation_IReferenceProtocol {
    /// Gets the type that is represented as an IPropertyValue.
    var value: T { try! _value() }
}

public enum WindowsFoundation_IReferenceProjection<TProjection: WinRTBoxableProjection>: WinRTInterfaceProjection {
    public typealias SwiftObject = WindowsFoundation_IReference<TProjection.SwiftValue>
    public typealias COMInterface = WindowsRuntime_ABI.SWRT_WindowsFoundation_IReference
    public typealias COMVirtualTable = WindowsRuntime_ABI.SWRT_WindowsFoundation_IReferenceVTable

    public static var typeName: String { fatalError("Windows.Foundation.IReference`1<\(TProjection.typeName)>") }
    public static var interfaceID: COMInterfaceID { TProjection.ireferenceID }
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &virtualTable) { $0 } }

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

        private var _lazyIPropertyValue: COMLazyReference<WindowsRuntime_ABI.SWRT_WindowsFoundation_IPropertyValue> = .init()
        public var _ipropertyValue: COMInterop<WindowsRuntime_ABI.SWRT_WindowsFoundation_IPropertyValue> {
            get throws {
                try _lazyIPropertyValue.getInterop {
                    try _queryInterface(WindowsRuntime_ABI.SWRT_WindowsFoundation_IPropertyValue.iid)
                        .reinterpret(to: WindowsRuntime_ABI.SWRT_WindowsFoundation_IPropertyValue.self)
                }
            }
        }

        public func _type() throws -> WindowsFoundation_PropertyType {
            try _ipropertyValue.get_Type()
        }

        public func _isNumericScalar() throws -> Bool {
            try _ipropertyValue.get_IsNumericScalar()
        }

        public func _value() throws -> T {
            var abiValue = TProjection.abiDefaultValue
            try withUnsafeMutablePointer(to: &abiValue) { abiValuePointer in
                try _interop.get_Value(abiValuePointer)
            }
            return TProjection.toSwift(consuming: &abiValue)
        }

        public func _getABIValue(_ pointer: UnsafeMutableRawPointer) throws {
            try _interop.get_Value(pointer.bindMemory(to: TProjection.ABIValue.self, capacity: 1))
        }
    }
}

// A generic type cannot have stored properties,
// and closures converted to C function pointers cannot capture generic arguments.
fileprivate var virtualTable: WindowsRuntime_ABI.SWRT_WindowsFoundation_IReferenceVTable =  .init(
    QueryInterface: { COMExportedInterface.QueryInterface($0, $1, $2) },
    AddRef: { COMExportedInterface.AddRef($0) },
    Release: { COMExportedInterface.Release($0) },
    GetIids: { WinRTExportedInterface.GetIids($0, $1, $2) },
    GetRuntimeClassName: { WinRTExportedInterface.GetRuntimeClassName($0, $1) },
    GetTrustLevel: { WinRTExportedInterface.GetTrustLevel($0, $1) },
    get_Value: { this, value in
        guard let this else { return HResult.pointer.value }
        guard let this: any WindowsFoundation_IReferenceProtocolABI = COMExportBase.getImplementationUnsafe(this) else {
            return HResult.fail.value
        }
        guard let value else { return HResult.pointer.value }
        return HResult.catch { try this._getABIValue(value) }.value
    })

#if swift(>=5.10)
extension WindowsRuntime_ABI.SWRT_WindowsFoundation_IReference: @retroactive WindowsRuntime.COMIInspectableStruct {}
#else
extension WindowsRuntime_ABI.SWRT_WindowsFoundation_IReference: WindowsRuntime.COMIInspectableStruct {}
#endif

extension COMInterop where Interface == WindowsRuntime_ABI.SWRT_WindowsFoundation_IReference {
    public func get_Value(_ value: UnsafeMutableRawPointer) throws {
        try HResult.throwIfFailed(this.pointee.VirtualTable.pointee.get_Value(this, value))
    }
}