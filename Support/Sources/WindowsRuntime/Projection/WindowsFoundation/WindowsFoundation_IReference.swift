/// Enables arbitrary enumerations, structures, and delegate types to be used as property values.
///
/// This interface has two uses in WinRT:
/// - Boxing primitives, value types and delegates to IInspectable.
/// - Providing a representation for nullable primitives, value types and delegates (since reference types can be null).
public typealias WindowsFoundation_IReference<T> = any WindowsFoundation_IReferenceProtocol<T>

/// Allows nongeneric uses of the IReference protocol.
public protocol WindowsFoundation_IReferenceProtocolABI {
    func _getABIValue(_ pointer: UnsafeMutableRawPointer) throws
}

/// Enables arbitrary enumerations, structures, and delegate types to be used as property values.
public protocol WindowsFoundation_IReferenceProtocol<T>: WindowsFoundation_IPropertyValueProtocol, WindowsFoundation_IReferenceProtocolABI {
    associatedtype T

    /// Gets the type that is represented as an IPropertyValue.
    var value: T { get throws }
}

import SWRT_WindowsFoundation

public enum WindowsFoundation_IReferenceBinding<TBinding: IReferenceableBinding>: InterfaceBinding {
    public typealias SwiftObject = WindowsFoundation_IReference<TBinding.SwiftValue>

    // Our ABI-level IReference<T> definition is nongeneric.
    // We can do this because the pointer in get_Value(T*) has the same ABI representation for all T's.
    // This allows us to avoid generating ABI code and projections for each IReference<T>,
    // and hence centralize the logic for dealing with this type in the support module.
    public typealias ABIStruct = SWRT_WindowsFoundation_IReference

    public static var typeName: String { fatalError("Windows.Foundation.IReference`1<\(TBinding.typeName)>") }
    public static var interfaceID: COMInterfaceID { TBinding.ireferenceID }
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        Import(_wrapping: consume reference)
    }

    public static func toCOM(_ value: SwiftObject) throws -> ABIReference {
        try Import.toCOM(value)
    }

    private final class Import
            : WinRTImport<WindowsFoundation_IReferenceBinding<TBinding>>,
            WindowsFoundation_IReferenceProtocol {
        public typealias T = TBinding.SwiftValue

        private var _lazyIPropertyValue: COMReference<SWRT_WindowsFoundation_IPropertyValue>.Optional = .none
        public var _ipropertyValue: COMInterop<SWRT_WindowsFoundation_IPropertyValue> {
            get throws {
                try _lazyIPropertyValue.lazyInitInterop {
                    try _queryInterface(uuidof(SWRT_WindowsFoundation_IPropertyValue.self))
                }
            }
        }

        public var type: WindowsFoundation_PropertyType {
            get throws { try _ipropertyValue.get_Type() }
        }

        public var isNumericScalar: Bool {
            get throws { try _ipropertyValue.get_IsNumericScalar() }
        }

        public var value: T {
            get throws {
                var abiValue = TBinding.abiDefaultValue
                try withUnsafeMutablePointer(to: &abiValue) { abiValuePointer in
                    try _interop.get_Value(abiValuePointer)
                }
                return TBinding.fromABI(consuming: &abiValue)
            }
        }

        public func _getABIValue(_ pointer: UnsafeMutableRawPointer) throws {
            try _interop.get_Value(pointer.bindMemory(to: TBinding.ABIValue.self, capacity: 1))
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
        guard let this, let value else { return WinRTError.toABI(hresult: HResult.invalidArg) }
        guard let reference: any WindowsFoundation_IReferenceProtocolABI = COMEmbedding.getImplementation(this) else {
            return WinRTError.toABI(hresult: HResult.fail, message: "Swift object should implement IReferenceProtocolABI")
        }
        return WinRTError.toABI { try reference._getABIValue(value) }
    })

extension COMInterop where ABIStruct == SWRT_WindowsFoundation_IReference {
    public func get_Value(_ value: UnsafeMutableRawPointer) throws {
        try WinRTError.fromABI(this.pointee.VirtualTable.pointee.get_Value(this, value))
    }
}