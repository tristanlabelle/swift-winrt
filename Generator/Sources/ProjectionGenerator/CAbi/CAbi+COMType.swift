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
        guard case .bound(let type) = type else { fatalError() }

        if type.definition.namespace == "System" {
            guard let mangledName = getName(systemTypeName: type.definition.name, mangled: false) else {
                throw WinMDError.unexpectedType
            }
            return makeCType(name: mangledName)
        }

        var comType = CType.reference(name: try CAbi.mangleName(type: type))
        if type.definition.isReferenceType { comType = comType.makePointer() }
        return comType
    }
}