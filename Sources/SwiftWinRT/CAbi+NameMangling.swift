import DotNetMD

extension CAbi {
    public static let vtableSuffix = "Vtbl"

    public static func mangleName(type: BoundType) -> String {
        var output = String()
        writeMangledName(type: type, to: &output)
        return output
    }

    public static func mangleName(type: TypeNode) -> String {
        var output = String()
        writeMangledName(type: type, to: &output)
        return output
    }

    public static func writeMangledName(type: BoundType, to output: inout some TextOutputStream) {
        output.write("__x_ABI_")
        if let namespace = type.definition.namespace {
            for namespaceComponent in namespace.split(separator: ".") {
                output.write("C")
                output.write(String(namespaceComponent.replacing("_", with: "__z")))
                output.write("_")
            }
        }

        if type.genericArgs.isEmpty {
            output.write("C")
            output.write(type.definition.name)
        }
        else {
            output.write("F")
            output.write(type.definition.nameWithoutGenericSuffix)
            output.write("_")
            output.write(String(type.genericArgs.count))
            output.write("_")
            for (index, genericArg) in type.genericArgs.enumerated() {
                if index > 0 {
                    output.write("_")
                }
                writeMangledName(type: genericArg, to: &output)
            }
        }
    }

    public static func writeMangledName(type: TypeNode, to output: inout some TextOutputStream) {
        if case let .bound(boundType) = type {
            writeMangledName(type: boundType, to: &output)
        }
        else {
            fatalError("Not implemented")
        }
    }
}