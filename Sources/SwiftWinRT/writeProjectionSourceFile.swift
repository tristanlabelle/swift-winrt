import DotNetMD
import CodeWriters

func writeProjectionSourceFile(assembly: Assembly, namespace: String, to output: some TextOutputStream) {
    let sourceFileWriter = SourceFileWriter(output: output)

    sourceFileWriter.writeImport(module: "Foundation") // For Foundation.UUID

    for typeDefinition in assembly.definedTypes.filter({ $0.namespace == namespace && $0.visibility == .public }) {
        if let interfaceDefinition = typeDefinition as? InterfaceDefinition {
            writeProtocol(interfaceDefinition, to: sourceFileWriter)
        }
        else {
            writeTypeDefinition(typeDefinition, to: sourceFileWriter)
        }
    }
}

fileprivate func writeTypeDefinition(_ typeDefinition: TypeDefinition, to writer: some SwiftTypeDeclarationWriter) {
    let visibility = toSwiftVisibility(typeDefinition.visibility)
    if let classDefinition = typeDefinition as? ClassDefinition {
        writer.writeClass(
            visibility: visibility == .public && !typeDefinition.isSealed ? .open : .public,
            final: typeDefinition.isSealed,
            name: typeDefinition.nameWithoutGenericSuffix,
            typeParameters: typeDefinition.genericParams.map { $0.name },
            base: toSwiftBaseType(typeDefinition.base),
            protocolConformances: typeDefinition.baseInterfaces.compactMap { toSwiftBaseType($0.interface) }) {
            writer in
            writeFields(of: classDefinition, to: writer, defaultInit: false)
            writeMembers(of: classDefinition, to: writer)
        }
    }
    else if typeDefinition is StructDefinition {
        let protocolConformances = typeDefinition.baseInterfaces.compactMap { toSwiftBaseType($0.interface) }
            + [ .identifier(name: "Hashable"), .identifier(name: "Codable") ]
        writer.writeStruct(
            visibility: visibility,
            name: typeDefinition.nameWithoutGenericSuffix,
            typeParameters: typeDefinition.genericParams.map { $0.name },
            protocolConformances: protocolConformances) {
            writer in writeFields(of: typeDefinition, to: writer, defaultInit: true)
        }
    }
    else if let enumDefinition = typeDefinition as? EnumDefinition {
        try? writer.writeEnum(
            visibility: visibility,
            name: enumDefinition.name,
            rawValueType: toSwiftType(enumDefinition.underlyingType.bindNode()),
            protocolConformances: [ .identifier(name: "Hashable"), .identifier(name: "Codable") ]) {
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

fileprivate func writeFields(of typeDefinition: TypeDefinition, to writer: SwiftRecordBodyWriter, defaultInit: Bool) {
    // FIXME: Rather switch on TypeDefinition to properly handle enum cases
    func getDefaultValue(_ type: SwiftType) -> String? {
        if case .optional = type { return "nil" }
        guard case .identifierChain(let chain) = type,
            chain.identifiers.count == 1 else { return nil }
        switch chain.identifiers[0].name {
            case "Bool": return "false"
            case "Int", "UInt", "Int8", "UInt8", "Int16", "UInt16", "Int32", "UInt32", "Int64", "UInt64": return "0"
            case "Float", "Double": return "0.0"
            case "String": return "\"\""
            default: return ".init()"
        }
    }

    for field in typeDefinition.fields.filter({ $0.visibility == .public }) {
        let type = try! toSwiftType(field.type)
        writer.writeStoredProperty(
            visibility: toSwiftVisibility(field.visibility),
            static: field.isStatic,
            let: false,
            name: pascalToCamelCase(field.name),
            type: type,
            defaultValue: defaultInit ? getDefaultValue(type) : nil)
    }
}

fileprivate func writeMembers(of classDefinition: ClassDefinition, to writer: SwiftRecordBodyWriter) {
    for property in classDefinition.properties.filter({ (try? $0.visibility) == .public }) {
        try? writer.writeProperty(
            visibility: toSwiftVisibility(property.visibility),
            static: property.isStatic,
            name: pascalToCamelCase(property.name),
            type: toSwiftType(property.type, allowImplicitUnwrap: true),
            get: { $0.writeFatalError("Not implemented") })
    }

    for method in classDefinition.methods.filter({ $0.visibility == .public }) {
        guard !method.isAccessor else { continue }
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

fileprivate func writeProtocol(_ interface: InterfaceDefinition, to writer: SwiftSourceFileWriter) {
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
            guard !method.isAccessor else { continue }
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

extension Method {
    var isAccessor: Bool {
        let prefixes = [ "get_", "set_", "put_", "add_", "remove_"]
        return prefixes.contains(where: { name.starts(with: $0) })
    }
}