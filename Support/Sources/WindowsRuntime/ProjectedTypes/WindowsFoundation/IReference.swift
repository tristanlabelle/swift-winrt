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

import SWRT_WindowsFoundation

public enum WindowsFoundation_IReferenceProjection<TProjection: BoxableProjection>: InterfaceProjection {
    public typealias SwiftObject = WindowsFoundation_IReference<TProjection.SwiftValue>
    public typealias ABIStruct = SWRT_WindowsFoundation_IReference

    public static var typeName: String { fatalError("Windows.Foundation.IReference`1<\(TProjection.typeName)>") }
    public static var interfaceID: COMInterfaceID { TProjection.ireferenceID }
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        Import(_wrapping: consume reference)
    }

    public static func toCOM(_ value: SwiftObject) throws -> ABIReference {
        try Import.toCOM(value)
    }

    private final class Import
            : WinRTImport<WindowsFoundation_IReferenceProjection<TProjection>>,
            WindowsFoundation_IReferenceProtocol {
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
fileprivate var virtualTable: SWRT_WindowsFoundation_IReference_VirtualTable =  .init(
    QueryInterface: { IUnknownVirtualTable.QueryInterface($0, $1, $2) },
    AddRef: { IUnknownVirtualTable.AddRef($0) },
    Release: { IUnknownVirtualTable.Release($0) },
    GetIids: { IInspectableVirtualTable.GetIids($0, $1, $2) },
    GetRuntimeClassName: { IInspectableVirtualTable.GetRuntimeClassName($0, $1) },
    GetTrustLevel: { IInspectableVirtualTable.GetTrustLevel($0, $1) },
    get_Value: { this, value in
        guard let this, let value else { return HResult.invalidArg.value }
        guard let reference: any WindowsFoundation_IReferenceProtocolABI = COMEmbedding.getImplementation(this) else {
            return HResult.fail.value
        }
        return HResult.catch { try reference._getABIValue(value) }.value
    })

extension COMInterop where ABIStruct == SWRT_WindowsFoundation_IReference {
    public func get_Value(_ value: UnsafeMutableRawPointer) throws {
        try HResult.throwIfFailed(this.pointee.VirtualTable.pointee.get_Value(this, value))
    }
}