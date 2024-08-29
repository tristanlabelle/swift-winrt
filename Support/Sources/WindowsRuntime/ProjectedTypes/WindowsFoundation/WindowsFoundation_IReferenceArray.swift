/// Enables arrays of arbitrary enumerations, structures, and delegate types to be used as property values.
public typealias WindowsFoundation_IReferenceArray<T> = any WindowsFoundation_IReferenceArrayProtocol<T>

/// Allows nongeneric uses of the IReferenceArray protocol.
public protocol WindowsFoundation_IReferenceArrayProtocolABI {
    func _getABIValue(_ length: inout UInt32, _ pointer: inout UnsafeMutableRawPointer?) throws
}

/// Enables arbitrary enumerations, structures, and delegate types to be used as property values.
public protocol WindowsFoundation_IReferenceArrayProtocol<T>: WindowsFoundation_IPropertyValueProtocol, WindowsFoundation_IReferenceArrayProtocolABI {
    associatedtype T

    /// Gets the type that is represented as an IPropertyValue.
    func _value() throws -> [T]
}

extension WindowsFoundation_IReferenceArrayProtocol {
    /// Gets the type that is represented as an IPropertyValue.
    var value: [T] { try! _value() }
}

import SWRT_WindowsFoundation

public enum WindowsFoundation_IReferenceArrayProjection<TProjection: IReferenceableProjection>: InterfaceProjection {
    public typealias SwiftObject = WindowsFoundation_IReferenceArray<TProjection.SwiftValue>

    // Our ABI-level IReferenceArray<T> definition is nongeneric, see IReference<T> for why.
    public typealias ABIStruct = SWRT_WindowsFoundation_IReferenceArray

    public static var typeName: String { fatalError("Windows.Foundation.IReferenceArray`1<\(TProjection.typeName)>") }
    public static var interfaceID: COMInterfaceID { TProjection.ireferenceArrayID }
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        Import(_wrapping: consume reference)
    }

    public static func toCOM(_ value: SwiftObject) throws -> ABIReference {
        try Import.toCOM(value)
    }

    private final class Import
            : WinRTImport<WindowsFoundation_IReferenceArrayProjection<TProjection>>,
            WindowsFoundation_IReferenceArrayProtocol {
        public typealias T = TProjection.SwiftValue

        private var _lazyIPropertyValue: COMReference<SWRT_WindowsFoundation_IPropertyValue>.Optional = .none
        public var _ipropertyValue: COMInterop<SWRT_WindowsFoundation_IPropertyValue> {
            get throws {
                try _lazyIPropertyValue.lazyInitInterop {
                    try _queryInterface(uuidof(SWRT_WindowsFoundation_IPropertyValue.self))
                }
            }
        }

        public func _type() throws -> WindowsFoundation_PropertyType {
            try _ipropertyValue.get_Type()
        }

        public func _isNumericScalar() throws -> Bool {
            try _ipropertyValue.get_IsNumericScalar()
        }

        public func _value() throws -> [T] {
            var length: UInt32 = 0
            var pointer: UnsafeMutableRawPointer? = nil
            try _interop.get_Value(&length, &pointer)
            guard let pointer else { return [] }

            var abiValue = COMArray<TProjection.ABIValue>(
                pointer: pointer.bindMemory(to: TProjection.ABIValue.self, capacity: Int(length)),
                count: length)
            return ArrayProjection<TProjection>.toSwift(consuming: &abiValue)
        }

        public func _getABIValue(_ length: inout UInt32, _ pointer: inout UnsafeMutableRawPointer?) throws {
            try _interop.get_Value(&length, &pointer)
        }
    }
}

// A generic type cannot have stored properties,
// and closures converted to C function pointers cannot capture generic arguments.
fileprivate var virtualTable: SWRT_WindowsFoundation_IReferenceArray_VirtualTable =  .init(
    QueryInterface: { IUnknownVirtualTable.QueryInterface($0, $1, $2) },
    AddRef: { IUnknownVirtualTable.AddRef($0) },
    Release: { IUnknownVirtualTable.Release($0) },
    GetIids: { IInspectableVirtualTable.GetIids($0, $1, $2) },
    GetRuntimeClassName: { IInspectableVirtualTable.GetRuntimeClassName($0, $1) },
    GetTrustLevel: { IInspectableVirtualTable.GetTrustLevel($0, $1) },
    get_Value: { this, length, pointer in
        guard let this, let length, let pointer else { return HResult.invalidArg.value }
        guard let reference: any WindowsFoundation_IReferenceArrayProtocolABI = COMEmbedding.getImplementation(this) else {
            return HResult.fail.value
        }
        return HResult.catch { try reference._getABIValue(&length.pointee, &pointer.pointee) }.value
    })

extension COMInterop where ABIStruct == SWRT_WindowsFoundation_IReferenceArray {
    public func get_Value(_ length: inout UInt32, _ pointer: inout UnsafeMutableRawPointer?) throws {
        try HResult.throwIfFailed(this.pointee.VirtualTable.pointee.get_Value(this, &length, &pointer))
    }
}