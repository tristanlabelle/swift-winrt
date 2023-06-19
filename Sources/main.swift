// import SwiftSyntax
// import SwiftBasicFormat
// import SwiftSyntaxBuilder
import DotNetMD
import Foundation

let namespace = CommandLine.arguments.dropFirst().first ?? "Windows.Storage"

struct AssemblyNotFound: Error {}
let context = MetadataContext(assemblyResolver: { _ in throw AssemblyNotFound() })
let assembly = try context.loadAssembly(path: #"C:\Program Files (x86)\Windows Kits\10\UnionMetadata\10.0.22000.0\Windows.winmd"#)

public struct StdoutOutputStream: TextOutputStream {
    public mutating func write(_ str: String) { fputs(str, stdout) }
}

let fileWriter = SwiftFileWriter(codeWriter: CodeWriter(output: StdoutOutputStream()))
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
    // else if let delegateDefinition = typeDefinition as? DelegateDefinition {
    //     MemberDeclListItem(decl: ProtocolDecl(identifier: interfaceDefinition.name))
    // }
}

func writeStructOrClass(_ typeDefinition: TypeDefinition, to writer: some SwiftTypeDeclarationWriter) {
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

func writeMembers(of typeDefinition: TypeDefinition, to writer: SwiftRecordBodyWriter) {
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
            parameters: {
                for param in method.params {
                    $0.writeParameter(name: param.name!, type: toSwiftType(param.type))
                }
            },
            throws: true,
            returnType: toSwiftType(method.returnType)) { $0.writeFatalError("Not implemented") }
    }
}

func writeProtocol(_ interface: InterfaceDefinition, to writer: SwiftFileWriter) {
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
                parameters: {
                    for param in method.params {
                        $0.writeParameter(name: param.name!, type: toSwiftType(param.type))
                    }
                },
                throws: true,
                returnType: toSwiftType(method.returnType))
        }
    }

    writer.writeTypeAlias(name: interface.name, target: "Any" + interface.name)
}

func writeEnum(_ enumDefinition: EnumDefinition, to writer: some SwiftTypeDeclarationWriter) {
    writer.writeEnum(name: enumDefinition.name) {
        for field in enumDefinition.fields.filter({ $0.visibility == .public && $0.isStatic }) {
            $0.writeCase(name: pascalToCamelCase(field.name))
        }
    }
}

func toSwiftType(_ type: BoundType) -> String {
    switch type {
        case let .definition(type):
            var result = ""
            if type.definition is InterfaceDefinition {
                result += "Any"
            }

            result += trimGenericParamCount(type.definition.name)

            if !type.genericArgs.isEmpty {
                result += "<"
                for (i, arg) in type.genericArgs.enumerated() {
                    if i > 0 {
                        result += ", "
                    }
                    result += toSwiftType(arg)
                }
                result += ">"
            }

            if (type.definition is InterfaceDefinition || type.definition is ClassDefinition)
                && type.definition.fullName != "System.String" {
                result += "?"
            }

            return result

        case let .array(element):
            return "[\(toSwiftType(element))]"

        case let .genericArg(param):
            return param.name

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