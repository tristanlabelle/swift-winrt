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
        guard case .bound(let type) = type else { throw UnexpectedTypeError(type.description) }

        if let systemType = try toSystemType(type.definition) {
            return makeCType(name: getName(systemType: systemType, mangled: false))
        }

        if type.definition.namespace == "Windows.Foundation" {
            switch type.definition.name {
                case "EventRegistrationToken": return makeCType(name: eventRegistrationTokenName)
                case "HResult": return makeCType(name: hresultName)
                default: break
            }
        }

        // At the ABI level, WinRT classes are represented as pointers to their default interface.
        if let classDefinition = type.definition as? ClassDefinition {
            guard !classDefinition.isStatic else { throw UnexpectedTypeError(classDefinition.fullName, reason: "Values should not be of static class types.") }
            guard let defaultInterface = try DefaultAttribute.getDefaultInterface(classDefinition) else { throw WinMDError.missingAttribute }
            return try toCType(defaultInterface.asNode)
        }

        var comType = CType.reference(name: try CAbi.mangleName(type: type))
        if type.definition.isReferenceType { comType = comType.makePointer() }
        return comType
    }
}