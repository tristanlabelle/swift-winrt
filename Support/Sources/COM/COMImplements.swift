import COM_ABI

/// Use as a stored property of a class to allow the object to be referenced
/// as a COM object exposing a given interface.
public struct COMImplements<InterfaceBinding: COMTwoWayBinding>: ~Copyable {
    private var embedding: COMEmbedding = .init(virtualTable: InterfaceBinding.exportedVirtualTable, owner: nil)

    public init() {}

    public mutating func toCOM(owner: InterfaceBinding.SwiftObject) -> InterfaceBinding.ABIReference {
        // The owner should conform to IUnknownProtocol and hence be an AnyObject,
        // but this cannot be expressed in the type system.
        toCOM(owner: owner as! IUnknown)
    }

    internal mutating func toCOM(owner: IUnknown) -> InterfaceBinding.ABIReference {
        embedding.initOwner(owner)
        return embedding.toCOM().cast()
    }
}