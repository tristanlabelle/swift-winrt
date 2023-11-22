import CodeWriters
import DotNetMetadata

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
            switch type.definition.name {
                case "Void": return makeCType(name: "void")

                case "Boolean": return makeCType(name: "bool")

                case "SByte": return makeCType(name: "int8_t")
                case "Byte": return makeCType(name: "uint8_t")
                case "Int16": return makeCType(name: "int16_t")
                case "UInt16": return makeCType(name: "uint16_t")
                case "Int32": return makeCType(name: "int32_t")
                case "UInt32": return makeCType(name: "uint32_t")
                case "Int64": return makeCType(name: "int64_t")
                case "UInt64": return makeCType(name: "uint64_t")
                case "IntPtr": return makeCType(name: "intptr_t")
                case "UIntPtr": return makeCType(name: "uintptr_t")

                case "Single": return makeCType(name: "float")
                case "Double": return makeCType(name: "double")

                case "Char": return makeCType(name: "char16_t")

                // TODO: Define own types for these
                case "Object": return makeCType(name: "IInspectable")
                case "String": return makeCType(name: "HSTRING")
                case "Guid": return makeCType(name: "GUID")
                default: fatalError("Not implemented")
            }
        }

        var comType = CType.reference(name: try CAbi.mangleName(type: type))
        if type.definition.isReferenceType { comType = comType.makePointer() }
        return comType
    }
}