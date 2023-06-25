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

let fileWriter = FileWriter(output: StdoutOutputStream())
fileWriter.writeImport(module: "Foundation") // For Foundation.UUID

for typeDefinition in assembly.definedTypes.filter({ $0.namespace == namespace && $0.visibility == .public }) {
    if let interfaceDefinition = typeDefinition as? InterfaceDefinition {
        writeProtocol(interfaceDefinition, to: fileWriter)
    }
    else {
        writeTypeDefinition(typeDefinition, to: fileWriter)
    }
}

func writeTypeDefinition(_ typeDefinition: TypeDefinition, to writer: some TypeDeclarationWriter) {
    let visibility = toSwiftVisibility(typeDefinition.visibility)
    if typeDefinition is ClassDefinition {
        writer.writeClass(
            visibility: visibility == .public && !typeDefinition.isSealed ? .open : .public,
            name: typeDefinition.nameWithoutGenericSuffix,
            typeParameters: typeDefinition.genericParams.map { $0.name }) {

            writeMembers(of: typeDefinition, to: $0)
        }
    }
    else if typeDefinition is StructDefinition {
        writer.writeStruct(
            visibility: visibility,
            name: typeDefinition.nameWithoutGenericSuffix,
            typeParameters: typeDefinition.genericParams.map { $0.name }) {

            writeMembers(of: typeDefinition, to: $0)
        }
    }
    else if let enumDefinition = typeDefinition as? EnumDefinition {
        try? writer.writeEnum(
            visibility: visibility,
            name: enumDefinition.name,
            rawValueType: toSwiftType(enumDefinition.underlyingType.bindNonGeneric())) {
            writer in
            for field in enumDefinition.fields.filter({ $0.visibility == .public && $0.isStatic }) {
                try? writer.writeCase(
                    name: pascalToCamelCase(field.name),
                    rawValue: toSwiftConstant(field.literalValue!))
            }
        }
    }
    else if let delegateDefinition = typeDefinition as? DelegateDefinition {
        try? writer.writeTypeAlias(
            visibility: visibility,
            name: typeDefinition.nameWithoutGenericSuffix,
            typeParameters: delegateDefinition.genericParams.map { $0.name },
            target: .function(
                params: delegateDefinition.invokeMethod.params.map { toSwiftType($0.type) },
                throws: true,
                returnType: toSwiftType(delegateDefinition.invokeMethod.returnType)
            )
        )
    }
}

func writeMembers(of typeDefinition: TypeDefinition, to writer: RecordBodyWriter) {
    for field in typeDefinition.fields.filter({ $0.visibility == .public }) {
        try? writer.writeStoredProperty(
            visibility: toSwiftVisibility(field.visibility),
            static: field.isStatic,
            let: false,
            name: pascalToCamelCase(field.name),
            type: toSwiftType(field.type))
    }

    for property in typeDefinition.properties.filter({ (try? $0.visibility) == .public }) {
        try? writer.writeProperty(
            visibility: toSwiftVisibility(property.visibility),
            static: property.isStatic,
            name: pascalToCamelCase(property.name),
            type: toSwiftType(property.type, allowImplicitUnwrap: true),
            get: { $0.writeFatalError("Not implemented") })
    }

    for method in typeDefinition.methods.filter({ $0.visibility == .public }) {
        guard !isAccessor(method) else { continue }
        if method is Constructor {
            try? writer.writeInit(
                visibility: toSwiftVisibility(method.visibility),
                parameters: method.params.map(toSwiftParameter),
                throws: true) { $0.writeFatalError("Not implemented") }
        }
        else {
            try? writer.writeFunc(
                visibility: toSwiftVisibility(method.visibility),
                static: method.isStatic,
                name: pascalToCamelCase(method.name),
                typeParameters: method.genericParams.map { $0.name },
                parameters: method.params.map(toSwiftParameter),
                throws: true,
                returnType: toSwiftReturnType(method.returnType)) { $0.writeFatalError("Not implemented") }
        }
    }
}

func writeProtocol(_ interface: InterfaceDefinition, to writer: FileWriter) {
    writer.writeProtocol(
            visibility: toSwiftVisibility(interface.visibility),
        name: interface.nameWithoutGenericSuffix,
        typeParameters: interface.genericParams.map { $0.name }) {
        writer in
        for genericParam in interface.genericParams {
            writer.writeAssociatedType(name: genericParam.name)
        }

        for property in interface.properties.filter({ (try? $0.visibility) == .public }) {
            try? writer.writeProperty(
                static: property.isStatic,
                name: pascalToCamelCase(property.name),
                type: toSwiftType(property.type, allowImplicitUnwrap: true),
                set: property.setter != nil)
        }

        for method in interface.methods.filter({ $0.visibility == .public }) {
            guard !isAccessor(method) else { continue }
            try? writer.writeFunc(
                static: method.isStatic,
                name: pascalToCamelCase(method.name),
                typeParameters: method.genericParams.map { $0.name },
                parameters: method.params.map(toSwiftParameter),
                throws: true,
                returnType: toSwiftReturnType(method.returnType))
        }
    }

    writer.writeTypeAlias(
        visibility: toSwiftVisibility(interface.visibility),
        name: "Any" + interface.nameWithoutGenericSuffix,
        typeParameters: interface.genericParams.map { $0.name },
        target: .identifier(
            protocolModifier: .existential,
            name: interface.nameWithoutGenericSuffix,
            genericArgs: interface.genericParams.map { .identifier(name: $0.name) }))
}

func toSwiftVisibility(_ visibility: DotNetMD.Visibility) -> SwiftWriter.Visibility {
    switch visibility {
        case .compilerControlled: return .fileprivate
        case .private: return .private
        case .assembly: return .internal
        case .familyAndAssembly: return .internal
        case .familyOrAssembly: return .public
        case .family: return .public
        case .public: return .public
    }
}

func toSwiftType(mscorlibType: TypeDefinition, genericArgs: [BoundType]) -> SwiftType? {
    guard mscorlibType.namespace == "System" else { return nil }
    if genericArgs.isEmpty {
        switch mscorlibType.name {
            case "Int16", "UInt16", "Int32", "UInt32", "Int64", "UInt64", "Double", "String", "Void":
                return .identifier(name: mscorlibType.name)

            case "Boolean": return .bool
            case "SByte": return .int(bits: 8, signed: true)
            case "Byte": return .int(bits: 8, signed: false)
            case "IntPtr": return .int
            case "UIntPtr": return .uint
            case "Single": return .float
            case "Char": return .identifierChain("Unicode", "UTF16", "CodeUnit")
            case "Guid": return .identifierChain("Foundation", "UUID")
            case "Object": return .any

            default: return nil
        }
    }
    else {
        return nil
    }
}

func toSwiftType(_ type: BoundType, allowImplicitUnwrap: Bool = false) -> SwiftType {
    switch type {
        case let .definition(type):
            // Remap primitive types
            if type.definition.assembly === context.mscorlib,
                let result = toSwiftType(mscorlibType: type.definition, genericArgs: type.genericArgs) {
                return result
            }
            else if type.definition.assembly.name == "Windows",
                type.definition.assembly.version == .all255,
                type.definition.namespace == "Windows.Foundation",
                type.definition.name == "IReference`1"
                && type.genericArgs.count == 1 {
                return .optional(wrapped: toSwiftType(type.genericArgs[0]), implicitUnwrap: allowImplicitUnwrap)
            }

            let namePrefix = type.definition is InterfaceDefinition ? "Any" : ""
            let name = namePrefix + type.definition.nameWithoutGenericSuffix

            let genericArgs = type.genericArgs.map { toSwiftType($0) }
            var result: SwiftType = .identifier(name: name, genericArgs: genericArgs)
            if type.definition is InterfaceDefinition || type.definition is ClassDefinition
                && type.definition.fullName != "System.String" {
                result = .optional(wrapped: result, implicitUnwrap: allowImplicitUnwrap)
            }

            return result

        case let .array(element):
            return .optional(
                wrapped: .array(element: toSwiftType(element)),
                implicitUnwrap: allowImplicitUnwrap)

        case let .genericArg(param):
            return .identifier(name: param.name)

        default:
            fatalError()
    }
}

func toSwiftReturnType(_ type: BoundType) -> SwiftType? {
    if case let .definition(type) = type,
        type.definition === context.mscorlib?.specialTypes.void {
        return nil
    }
    return toSwiftType(type, allowImplicitUnwrap: true)
}

func toSwiftParameter(_ param: Param) -> Parameter {
    .init(label: "_", name: param.name!, `inout`: param.isByRef, type: toSwiftType(param.type))
}

func isAccessor(_ method: Method) -> Bool {
    let prefixes = ["get_", "set_", "put_", "add_", "remove_"]
    return prefixes.contains(where: { method.name.starts(with: $0) })
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