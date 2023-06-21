import DotNetMD
import SwiftWriter
import Foundation

let namespace = CommandLine.arguments.dropFirst().first ?? "Windows.Storage"

struct AssemblyNotFound: Error {}
let context = MetadataContext(assemblyResolver: { _ in throw AssemblyNotFound() })
let assembly = try context.loadAssembly(path: #"C:\Program Files (x86)\Windows Kits\10\UnionMetadata\10.0.22000.0\Windows.winmd"#)

public struct StdoutOutputStream: TextOutputStream {
    public mutating func write(_ str: String) { fputs(str, stdout) }
}

let fileWriter = FileWriter(codeWriter: CodeWriter(output: StdoutOutputStream()))
for typeDefinition in assembly.definedTypes.filter({ $0.namespace == namespace && $0.visibility == .public }) {
    if typeDefinition is ClassDefinition || typeDefinition is StructDefinition {
        writeStructOrClass(typeDefinition, to: fileWriter)
    }
    else if let interfaceDefinition = typeDefinition as? InterfaceDefinition {
        writeProtocol(interfaceDefinition, to: fileWriter)
    }
    else if let enumDefinition = typeDefinition as? EnumDefinition {
        writeEnum(enumDefinition, to: fileWriter)
    }
    else if let delegateDefinition = typeDefinition as? DelegateDefinition {
        fileWriter.writeTypeAlias(
            name: typeDefinition.name,
            target: .function(
                params: delegateDefinition.invokeMethod.params.map { toSwiftType($0.type) },
                throws: true,
                returnType: toSwiftType(delegateDefinition.invokeMethod.returnType)
            )
        )
    }
}

func writeStructOrClass(_ typeDefinition: TypeDefinition, to writer: some TypeDeclarationWriter) {
    if typeDefinition is StructDefinition {
        writer.writeStruct(name: typeDefinition.name) {
            writeMembers(of: typeDefinition, to: $0)
        }
    }
    else if typeDefinition is ClassDefinition {
        writer.writeClass(name: typeDefinition.name) {
            writeMembers(of: typeDefinition, to: $0)
        }
    }
}

func writeMembers(of typeDefinition: TypeDefinition, to writer: RecordBodyWriter) {
    for field in typeDefinition.fields.filter({ $0.visibility == .public && $0.isStatic }) {
        writer.writeStoredProperty(
            visibility: .public,
            static: field.isStatic,
            let: false,
            name: pascalToCamelCase(field.name),
            type: toSwiftType(field.type))
    }

    for property in typeDefinition.properties.filter({ $0.visibility == .public }) {
        writer.writeProperty(
            visibility: .public,
            name: pascalToCamelCase(property.name),
            type: toSwiftType(property.type),
            get: { $0.writeFatalError("Not implemented") })
    }

    for method in typeDefinition.methods.filter({ $0.visibility == .public }) {
        guard !isAccessor(method) else { continue }
        writer.writeFunc(
            visibility: .public,
            static: method.isStatic,
            name: pascalToCamelCase(method.name),
            parameters: method.params.map { Parameter(label: "_", name: $0.name!, type: toSwiftType($0.type)) },
            throws: true,
            returnType: toSwiftType(method.returnType)) { $0.writeFatalError("Not implemented") }
    }
}

func writeProtocol(_ interface: InterfaceDefinition, to writer: FileWriter) {
    writer.writeProtocol(name: interface.name) {
        for property in interface.properties.filter({ $0.visibility == .public }) {
            $0.writeProperty(
                name: pascalToCamelCase(property.name),
                type: toSwiftType(property.type),
                set: property.setter != nil)
        }

        for method in interface.methods.filter({ $0.visibility == .public }) {
            guard !isAccessor(method) else { continue }
            $0.writeFunc(
                static: method.isStatic,
                name: pascalToCamelCase(method.name),
                parameters: method.params.map { Parameter(label: "_", name: $0.name!, type: toSwiftType($0.type)) },
                throws: true,
                returnType: toSwiftType(method.returnType))
        }
    }

    writer.writeTypeAlias(name: "Any" + interface.name, target: .identifier(name: interface.name))
}

func writeEnum(_ enumDefinition: EnumDefinition, to writer: some TypeDeclarationWriter) {
    writer.writeEnum(name: enumDefinition.name) {
        for field in enumDefinition.fields.filter({ $0.visibility == .public && $0.isStatic }) {
            $0.writeCase(
                name: pascalToCamelCase(field.name),
                rawValue: toSwiftConstant(field.literalValue!))
        }
    }
}

func toSwiftType(_ type: BoundType, allowImplicitUnwrap: Bool = false) -> SwiftType {
    switch type {
        case let .definition(type):
            let namePrefix = type.definition is InterfaceDefinition ? "Any" : ""
            let name = namePrefix + trimGenericParamCount(type.definition.name)

            let genericArgs = type.genericArgs.map { toSwiftType($0) }
            var result: SwiftType = .identifier(name: name, genericArgs: genericArgs)
            if type.definition is InterfaceDefinition || type.definition is ClassDefinition
                && type.definition.fullName != "System.String" {
                result = .optional(wrapped: result, implicitUnwrap: allowImplicitUnwrap)
            }

            return result

        case let .array(element):
            return .array(element: toSwiftType(element))

        case let .genericArg(param):
            return .identifier(name: param.name)

        default:
            fatalError()
    }
}

func isAccessor(_ method: Method) -> Bool {
    let prefixes = ["get_", "set_", "put_", "add_", "remove_"]
    return prefixes.contains(where: { method.name.starts(with: $0) })
}

func trimGenericParamCount(_ str: String) -> String {
    guard let index = str.firstIndex(of: "`") else { return str }
    return String(str[..<index])
}

func pascalToCamelCase(_ str: String) -> String {
    // "" -> ""
    // fooBar -> fooBar
    guard str.first?.isUppercase == true else { return str }
    var lastUpperCaseIndex = str.startIndex
    while true {
        let nextIndex = str.index(after: lastUpperCaseIndex)
        guard nextIndex < str.endIndex else { break }
        guard str[nextIndex].isUppercase else { break }
        lastUpperCaseIndex = nextIndex
    }

    let firstNonUpperCaseIndex = str.index(after: lastUpperCaseIndex)

    // FOOBAR -> foobar
    if firstNonUpperCaseIndex == str.endIndex {
        return str.lowercased()
    }

    // FooBar -> fooBar
    if lastUpperCaseIndex == str.startIndex {
        return str[lastUpperCaseIndex].lowercased() + str[firstNonUpperCaseIndex...]
    }

    // UIElement -> uiElement
    return str[...lastUpperCaseIndex].lowercased() + str[firstNonUpperCaseIndex...]
}

func toSwiftConstant(_ constant: Constant) -> String {
    switch constant {
        case let .boolean(value): return value ? "true" : "false"
        case let .int8(value): return String(value)
        case let .int16(value): return String(value)
        case let .int32(value): return String(value)
        case let .int64(value): return String(value)
        case let .uint8(value): return String(value)
        case let .uint16(value): return String(value)
        case let .uint32(value): return String(value)
        case let .uint64(value): return String(value)
        case .null: return "nil"
        default: fatalError("Not implemented")
    }
}