import DotNetMD

enum CNameMangling {
    public static let vtblSuffix = "Vtbl"

    public static func mangle(typeDefinition: TypeDefinition, genericArgs: [BoundType]) -> String {
        var output = String()
        write(typeDefinition: typeDefinition, genericArgs: genericArgs, to: &output)
        return output
    }

    public static func write(typeDefinition: TypeDefinition, genericArgs: [BoundType], to output: inout some TextOutputStream) {
        // __x_ABI_CWindows_CFoundation_CIClosable
        // __x_ABI_C__FIReference_1_GUID
        // __x_ABI_C__FIMap_2_HSTRING___x_ABI_Ctest__zcomponent__CBase
        output.write("__x_ABI_")
        if let namespace = Optional(typeDefinition.namespace) {
            for namespaceComponent in namespace.split(separator: ".") {
                output.write("C")
                output.write(String(namespaceComponent.replacing("_", with: "__z")))
                output.write("_")
            }
        }

        output.write(genericArgs.isEmpty ? "C" : "F")
        output.write(typeDefinition.name)

        if !genericArgs.isEmpty {
            output.write("_")
            output.write(String(genericArgs.count))
            output.write("_")
            for (index, genericArg) in genericArgs.enumerated() {
                if index > 0 {
                    output.write("_")
                }
                write(type: genericArg, to: &output)
            }
        }
    }

    private static func write(type: BoundType, to output: inout some TextOutputStream) {
        if case let .definition(definition) = type {
            write(typeDefinition: definition.definition, genericArgs: definition.genericArgs, to: &output)
        }
        else {
            fatalError("Not implemented")
        }
    }
}