import DotNetMetadata
import CodeWriters
import Collections

extension SwiftProjection {
    static func writeSourceFile(assembly: Assembly, filter: (TypeDefinition) -> Bool, to output: some TextOutputStream) {
        let sourceFileWriter = SwiftSourceFileWriter(output: output)

        sourceFileWriter.writeImport(module: "Foundation") // For Foundation.UUID

        for typeDefinition in assembly.definedTypes.filter({ filter($0) && $0.visibility == .public }) {
            if let interfaceDefinition = typeDefinition as? InterfaceDefinition {
                writeProtocol(interfaceDefinition, to: sourceFileWriter)
            }
            else {
                writeTypeDefinition(typeDefinition, to: sourceFileWriter)
            }
        }
    }

    static func writeTypeDefinition(_ typeDefinition: TypeDefinition, to writer: some SwiftTypeDeclarationWriter) {
        let visibility = toVisibility(typeDefinition.visibility)
        if let classDefinition = typeDefinition as? ClassDefinition {
            // Do not generate Attribute classes since they are compile-time constructs
            if classDefinition.base?.definition.fullName == "System.Attribute" {
                return
            }

            writer.writeClass(
                visibility: visibility == .public && !typeDefinition.isSealed ? .open : .public,
                final: typeDefinition.isSealed,
                name: toTypeName(typeDefinition),
                typeParameters: typeDefinition.genericParams.map { $0.name },
                base: toBaseType(typeDefinition.base),
                protocolConformances: typeDefinition.baseInterfaces.compactMap { toBaseType($0.interface) }) {
                writer in
                writeTypeAliasesForBaseGenericArgs(of: classDefinition, to: writer)
                writeFields(of: classDefinition, to: writer, defaultInit: false)
                writeMembers(of: classDefinition, to: writer)
            }
        }
        else if typeDefinition is StructDefinition {
            let protocolConformances = typeDefinition.baseInterfaces.compactMap { toBaseType($0.interface) }
                + [ .identifier(name: "Hashable"), .identifier(name: "Codable") ]
            writer.writeStruct(
                visibility: visibility,
                name: toTypeName(typeDefinition),
                typeParameters: typeDefinition.genericParams.map { $0.name },
                protocolConformances: protocolConformances) {
                writer in writeFields(of: typeDefinition, to: writer, defaultInit: true)
            }
        }
        else if let enumDefinition = typeDefinition as? EnumDefinition {
            try? writer.writeEnum(
                visibility: visibility,
                name: toTypeName(enumDefinition),
                rawValueType: toType(enumDefinition.underlyingType.bindNode()),
                protocolConformances: [ .identifier(name: "Hashable"), .identifier(name: "Codable") ]) {
                writer in
                for field in enumDefinition.fields.filter({ $0.visibility == .public && $0.isStatic }) {
                    try? writer.writeCase(
                        name: Casing.pascalToCamel(field.name),
                        rawValue: toConstant(field.literalValue!))
                }
            }
        }
        else if let delegateDefinition = typeDefinition as? DelegateDefinition {
            try? writer.writeTypeAlias(
                visibility: visibility,
                name: toTypeName(typeDefinition),
                typeParameters: delegateDefinition.genericParams.map { $0.name },
                target: .function(
                    params: delegateDefinition.invokeMethod.params.map { toType($0.type) },
                    throws: true,
                    returnType: toType(delegateDefinition.invokeMethod.returnType)
                )
            )
        }
    }

    fileprivate static func writeTypeAliasesForBaseGenericArgs(of typeDefinition: TypeDefinition, to writer: SwiftRecordBodyWriter) {
        var baseTypes = typeDefinition.baseInterfaces.map { $0.interface }
        if let base = typeDefinition.base {
            baseTypes.insert(base, at: 0)
        }

        var typeAliases: Collections.OrderedDictionary<String, SwiftType> = .init()
        for baseType in baseTypes {
            for (i, genericArg) in baseType.fullGenericArgs.enumerated() {
                typeAliases[baseType.definition.fullGenericParams[i].name] = toType(genericArg)
            }
        }

        for entry in typeAliases {
            writer.writeTypeAlias(visibility: .public, name: entry.key, typeParameters: [], target: entry.value)
        }
    }

    fileprivate static func writeFields(of typeDefinition: TypeDefinition, to writer: SwiftRecordBodyWriter, defaultInit: Bool) {
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
            let type = try! toType(field.type)
            writer.writeStoredProperty(
                visibility: toVisibility(field.visibility),
                static: field.isStatic,
                let: false,
                name: Casing.pascalToCamel(field.name),
                type: type,
                defaultValue: defaultInit ? getDefaultValue(type) : nil)
        }
    }

    fileprivate static func writeMembers(of classDefinition: ClassDefinition, to writer: SwiftRecordBodyWriter) {
        for property in classDefinition.properties.filter({ $0.visibility == .public }) {
            try? writer.writeProperty(
                visibility: toVisibility(property.visibility),
                static: property.isStatic,
                name: Casing.pascalToCamel(property.name),
                type: toType(property.type, allowImplicitUnwrap: true),
                get: { $0.writeFatalError("Not implemented") })
        }

        for method in classDefinition.methods.filter({ $0.visibility == .public }) {
            guard !method.isAccessor else { continue }
            if method is Constructor {
                try? writer.writeInit(
                    visibility: toVisibility(method.visibility),
                    parameters: method.params.map(toParameter),
                    throws: true) { $0.writeFatalError("Not implemented") }
            }
            else {
                try? writer.writeFunc(
                    visibility: toVisibility(method.visibility),
                    static: method.isStatic,
                    name: Casing.pascalToCamel(method.name),
                    typeParameters: method.genericParams.map { $0.name },
                    parameters: method.params.map(toParameter),
                    throws: true,
                    returnType: toReturnType(method.returnType)) { $0.writeFatalError("Not implemented") }
            }
        }
    }

    static func writeProtocol(_ interface: InterfaceDefinition, to writer: SwiftSourceFileWriter) {
        writer.writeProtocol(
                visibility: toVisibility(interface.visibility),
            name: toTypeName(interface),
            typeParameters: interface.genericParams.map { $0.name }) {
            writer in
            for genericParam in interface.genericParams {
                writer.writeAssociatedType(name: genericParam.name)
            }

            for property in interface.properties.filter({ $0.visibility == .public }) {
                try? writer.writeProperty(
                    static: property.isStatic,
                    name: Casing.pascalToCamel(property.name),
                    type: toType(property.type, allowImplicitUnwrap: true),
                    set: property.setter != nil)
            }

            for method in interface.methods.filter({ $0.visibility == .public }) {
                guard !method.isAccessor else { continue }
                try? writer.writeFunc(
                    static: method.isStatic,
                    name: Casing.pascalToCamel(method.name),
                    typeParameters: method.genericParams.map { $0.name },
                    parameters: method.params.map(toParameter),
                    throws: true,
                    returnType: toReturnType(method.returnType))
            }
        }

        writer.writeTypeAlias(
            visibility: toVisibility(interface.visibility),
            name: "Any" + toTypeName(interface),
            typeParameters: interface.genericParams.map { $0.name },
            target: .identifier(
                protocolModifier: .existential,
                name: toTypeName(interface),
                genericArgs: interface.genericParams.map { .identifier(name: $0.name) }))
    }
}

extension Method {
    var isAccessor: Bool {
        let prefixes = [ "get_", "set_", "put_", "add_", "remove_"]
        return prefixes.contains(where: { name.starts(with: $0) })
    }
}