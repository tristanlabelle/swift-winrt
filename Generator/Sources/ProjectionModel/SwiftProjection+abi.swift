import CodeWriters
import DotNetMetadata
import WindowsMetadata

extension SwiftProjection {
    public func toABIType(_ type: BoundType) throws -> SwiftType {
        precondition(!(type.definition is ClassDefinition)) // Classes have no ABI representation
        return .chain(abiModuleName, try CAbi.mangleName(type: type))
    }

    public func toABIVirtualTableType(_ type: BoundType) throws -> SwiftType {
        precondition(type.definition is InterfaceDefinition || type.definition is DelegateDefinition)
        return .chain(abiModuleName, try CAbi.mangleName(type: type) + CAbi.virtualTableSuffix)
    }
}