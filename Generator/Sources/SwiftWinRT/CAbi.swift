import DotNetMetadata
import CodeWriters

enum CAbi {
    public static let interfaceIDPrefix = "IID_"
    public static let interfaceVTableSuffix = "Vtbl"

    public static func mangleName(type: BoundType) -> String {
        var output = String()
        writeMangledName(type: type, to: &output)
        return output
    }

    public static func writeMangledName(type: BoundType, to output: inout some TextOutputStream) {
        if type.definition.assembly is Mscorlib {
            assert(type.genericArgs.isEmpty && type.definition.namespace == "System")
            writeSystemTypeName(name: type.definition.name, to: &output)
            return
        }

        if type.genericArgs.isEmpty { output.write("__x_ABI_C") }
        writeInnerMangledName(type: type, to: &output)
    }

    private static func writeInnerMangledName(type: BoundType, to output: inout some TextOutputStream) {
        // __FIMap_2_HSTRING___FIVectorView_1_Windows__CData__CText__CTextSegment
        if type.definition.assembly is Mscorlib {
            assert(type.genericArgs.isEmpty && type.definition.namespace == "System")
            writeSystemTypeName(name: type.definition.name, to: &output)
            return
        }

        if type.genericArgs.isEmpty {
            if let namespace = type.definition.namespace {
                var first = true
                for namespaceComponent in namespace.split(separator: ".") {
                    if !first { output.write("C") }
                    output.write(String(namespaceComponent.replacing("_", with: "__z")))
                    output.write("_")
                    first = false
                }
            }

            output.write("C")
            output.write(type.definition.name)
        }
        else {
            output.write("__F")
            output.write(type.definition.nameWithoutGenericSuffix)
            output.write("_")
            output.write(String(type.genericArgs.count))
            output.write("_")
            for (index, genericArgNode) in type.genericArgs.enumerated() {
                if index > 0 {
                    output.write("_")
                }

                guard case .bound(let genericArg) = genericArgNode else {
                    fatalError("Invalid generic arg, must be a bound type.")
                }
                writeMangledName(type: genericArg, to: &output)
            }
        }
    }

    private static func writeSystemTypeName(name: String, to output: inout some TextOutputStream) {
        switch name {
            case "Boolean": output.write("boolean")
            case "Byte": output.write("byte")
            case "Int16", "UInt16", "Int32", "UInt32", "Int64", "UInt64":
                output.write(name.uppercased())
            case "Single": output.write("float")
            case "Double": output.write("double")
            case "Guid": output.write("GUID")
            case "String": output.write("HSTRING")
            case "Object": output.write("IInspectable")
            default: fatalError("Not implemented: ABI name for System.\(name)")
        }
    }

    public static func toCType(_ type: TypeNode) -> CType {
        if case let .bound(type) = type {
            // TODO: Handle special system types

            return CType(
                name: mangleName(type: type),
                pointerIndirections: type.definition.isReferenceType ? 1 : 0)
        }
        else {
            fatalError("Not implemented")
        }
    }
}