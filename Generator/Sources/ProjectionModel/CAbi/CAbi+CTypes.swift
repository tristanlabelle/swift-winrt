import CodeWriters
import DotNetMetadata
import WindowsMetadata

extension CAbi {
    internal static func makeCType(name: String, indirections: Int = 0, nullability: CNullability? = nil) -> CType {
        var type = CType.reference(name: name)
        for i in 0..<indirections {
            type = type.makePointer(nullability: i == indirections - 1 ? nullability : nil)
        }
        return type
    }

    internal static func makeCParam(type: String, indirections: Int = 0, nullability: CNullability? = nil, name: String?) -> CParamDecl {
        .init(type: makeCType(name: type, indirections: indirections, nullability: nullability), name: name)
    }

    internal static func toCType(_ type: TypeNode) throws -> CType {
        guard case .bound(let type) = type else { throw UnexpectedTypeError(type.description) }

        if type.definition.namespace == "System" {
            if type.definition.name == "Object" {
                return makeCType(name: iinspectableName).makePointer()
            } else if let primitiveType = WinRTPrimitiveType(fromSystemNamespaceType: type.definition.name) {
                return makeCType(name: getName(primitiveType: primitiveType, mangled: false))
            } else {
                throw UnexpectedTypeError(type.definition.fullName, reason: "Not a well-known WinRT system type")
            }
        }

        if type.definition.namespace == "Windows.Foundation" {
            switch type.definition.name {
                case "EventRegistrationToken": return makeCType(name: eventRegistrationTokenName)
                case "HResult": return makeCType(name: hresultName)
                case "IReference`1": return makeCType(name: ireferenceName).makePointer()
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