import DotNetMD

extension CAbi {
    public static let vtableSuffix = "Vtbl"

    public static func mangleName(typeDefinition: TypeDefinition, genericArgs: [BoundType] = []) -> String {
        var output = String()
        writeMangledName(typeDefinition: typeDefinition, genericArgs: genericArgs, to: &output)
        return output
    }

    public static func mangleName(type: BoundType) -> String {
        var output = String()
        writeMangledName(type: type, to: &output)
        return output
    }

    public static func writeMangledName(typeDefinition: TypeDefinition, genericArgs: [BoundType] = [], to output: inout some TextOutputStream) {
        output.write("__x_ABI_")
        if let namespace = Optional(typeDefinition.namespace) {
            for namespaceComponent in namespace.split(separator: ".") {
                output.write("C")
                output.write(String(namespaceComponent.replacing("_", with: "__z")))
                output.write("_")
            }
        }

        if genericArgs.isEmpty {
            output.write("C")
            output.write(typeDefinition.name)
        }
        else {
            output.write("F")
            output.write(typeDefinition.nameWithoutGenericSuffix)
            output.write("_")
            output.write(String(genericArgs.count))
            output.write("_")
            for (index, genericArg) in genericArgs.enumerated() {
                if index > 0 {
                    output.write("_")
                }
                writeMangledName(type: genericArg, to: &output)
            }
        }
    }

    public static func writeMangledName(type: BoundType, to output: inout some TextOutputStream) {
        if case let .definition(definition) = type {
            writeMangledName(typeDefinition: definition.definition, genericArgs: definition.genericArgs, to: &output)
        }
        else {
            fatalError("Not implemented")
        }
    }
}