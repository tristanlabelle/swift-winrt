import CodeWriters
import DotNetMetadata
import WindowsMetadata

extension CAbi {
    internal static func makeCType(name: String, indirections: Int = 0) -> CType {
        var type = CType.reference(name: name)
        for _ in 0..<indirections {
            type = type.makePointer()
        }
        return type
    }

    internal static func makeCParam(type: String, indirections: Int = 0, name: String?) -> CParamDecl {
        .init(type: makeCType(name: type, indirections: indirections), name: name)
    }

    internal static func toCType(_ type: TypeNode) throws -> CType {
        guard case .bound(let type) = type else { throw WinMDError.unexpectedType }
        guard let namespace = type.definition.namespace else { throw WinMDError.unexpectedType }

        if namespace == "System" || namespace.starts(with: "System.") {
            guard let mangledName = getName(systemTypeName: type.definition.name, mangled: false) else {
                throw WinMDError.unexpectedType
            }
            return makeCType(name: mangledName)
        }

        // At the ABI level, WinRT classes are represented as pointers to their default interface.
        if let classDefinition = type.definition as? ClassDefinition {
            guard !classDefinition.isStatic else { throw WinMDError.unexpectedType }
            guard let defaultInterface = try DefaultAttribute.getDefaultInterface(classDefinition) else { throw WinMDError.missingAttribute }
            return try toCType(defaultInterface.asNode)
        }

        var comType = CType.reference(name: try CAbi.mangleName(type: type))
        if type.definition.isReferenceType { comType = comType.makePointer() }
        return comType
    }
}