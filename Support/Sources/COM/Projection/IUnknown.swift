import COM_ABI

/// Represents an arbitrary COM object in Swift.
public typealias IUnknown = any IUnknownProtocol

/// Base protocol for the COM IUnknown interface in Swift.
/// Provides QueryInterface but leaves out AddRef/Release to be handled by the binding.
public protocol IUnknownProtocol: AnyObject {
    /// Gets an ABI-level reference to the COM interface implementing a given interface ID,
    /// or throws a COMError with E_NOINTERFACE.
    ///
    /// Note: We can't implement a stronger contract using a COMBinding generic type here
    /// because it supports implementations of QueryInterface calls coming from COM,
    /// which do not have the static type of the interface to be retrieved. 
    func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference
}

extension IUnknownProtocol {
    public func _queryInterface<ABIStruct>(
            _ id: COMInterfaceID, type: ABIStruct.Type = ABIStruct.self) throws -> COMReference<ABIStruct> {
        (try _queryInterface(id) as IUnknownReference).cast(to: type)
    }

    public func _queryInterface<Binding: COMBinding>(_: Binding.Type) throws -> Binding.ABIReference {
        try _queryInterface(Binding.interfaceID)
    }

    /// Queries this object for an additional COM interface described by the given binding.
    /// On failure, throws a COMError with an HResult of E_NOINTERFACE.
    public func queryInterface<Binding: COMBinding>(_: Binding.Type) throws -> Binding.SwiftObject {
        Binding.toSwift(try self._queryInterface(Binding.self))
    }
}

/// Binds C(++) IUnknown-based COM objects into Swift.
public enum IUnknownBinding: COMTwoWayBinding {
    public typealias ABIStruct = COM_ABI.SWRT_IUnknown
    public typealias SwiftObject = IUnknown

    public static var interfaceID: COMInterfaceID { uuidof(ABIStruct.self) }
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        Import(_wrapping: reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> ABIReference {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<IUnknownBinding> {}

    private static var virtualTable: COM_ABI.SWRT_IUnknown_VirtualTable = .init(
        QueryInterface: { IUnknownVirtualTable.QueryInterface($0, $1, $2) },
        AddRef: { IUnknownVirtualTable.AddRef($0) },
        Release: { IUnknownVirtualTable.Release($0) })
}

// Originally we extended SWRT_IUnknown to add a static let COMInterfaceID property,
// however this breaks down when a second Swift module has its own copy of the SWRT_IUnknown
// and references SWRT_IUnknown.iid. The Swift compiler then doesn't find the extension.
public func uuidof(_: COM_ABI.SWRT_IUnknown.Type) -> COMInterfaceID {
    .init(0x00000000, 0x0000, 0x0000, 0xC000, 0x000000000046)
}

public typealias IUnknownPointer = IUnknownBinding.ABIPointer
public typealias IUnknownReference = IUnknownBinding.ABIReference