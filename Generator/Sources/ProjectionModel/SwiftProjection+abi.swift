import CodeWriters
import DotNetMetadata
import WindowsMetadata

extension SwiftProjection {
    public func toABIType(_ type: BoundType) throws -> SwiftType {
        if let classDefinition = type.definition as? ClassDefinition {
            // The ABI representation of a (non-static) class is that of its default interface.
            precondition(!classDefinition.isStatic)
            guard let defaultInterface = try DefaultAttribute.getDefaultInterface(classDefinition) else {
                throw WinMDError.missingAttribute
            }
            return try toABIType(defaultInterface.asBoundType)
        }

        return .identifier(try CAbi.mangleName(type: type))
    }

    public func toABIVirtualTableType(_ type: BoundType) throws -> SwiftType {
        precondition(type.definition is InterfaceDefinition || type.definition is DelegateDefinition)
        return .identifier(try CAbi.mangleName(type: type) + CAbi.virtualTableSuffix)
    }
}