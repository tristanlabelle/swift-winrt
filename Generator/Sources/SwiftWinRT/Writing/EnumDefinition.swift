import CodeWriters
import DotNetMetadata
import ProjectionModel

internal func writeEnumDefinition(_ enumDefinition: EnumDefinition, projection: Projection, to writer: SwiftSourceFileWriter) throws {
    if SupportModules.WinRT.getBuiltInTypeKind(enumDefinition) != nil {
        // Defined in WindowsRuntime, merely reexport it here.
        let typeName = try projection.toTypeName(enumDefinition)
        writer.writeImport(exported: true, kind: .struct, module: SupportModules.WinRT.moduleName, symbolName: typeName)
        return
    }

    if try projection.isSwiftEnumEligible(enumDefinition) {
        try writeClosedEnumDefinition(enumDefinition, projection: projection, to: writer)
    }
    else {
        try writeOpenEnumDefinition(enumDefinition, projection: projection, to: writer)
    }
}

fileprivate func writeOpenEnumDefinition(_ enumDefinition: EnumDefinition, projection: Projection, to writer: SwiftSourceFileWriter) throws {
    // By default, enums are syntactic sugar for integers in .NET,
    // so we cannot guarantee that the enumerants are exhaustive,
    // therefore we cannot project them to Swift enums
    // since they would be unable to represent unknown values.
    let structName = try projection.toTypeName(enumDefinition)
    try writer.writeStruct(
            documentation: projection.getDocumentationComment(enumDefinition),
            visibility: Projection.toVisibility(enumDefinition.visibility),
            name: structName,
            protocolConformances: [ .identifier("CStyleEnum") ]) { writer throws in

        let rawValueType = try projection.toType(enumDefinition.underlyingType.bindNode())
        writer.writeStoredProperty(visibility: .public, declarator: .var, name: "rawValue", type: rawValueType)
        writer.writeInit(visibility: .public,
            params: [ .init(name: "rawValue", type: rawValueType, defaultValue: "0") ]) {
            $0.output.write("self.rawValue = rawValue")
        }

        for field in enumDefinition.fields.filter({ $0.visibility == .public && $0.isStatic }) {
            let value = Projection.toConstant(try field.literalValue!)
            // Avoid "warning: static property '<foo>' produces an empty option set"
            let initializer = value == "0" ? "Self()" : "Self(rawValue: \(value))"
            try writer.writeStoredProperty(
                documentation: projection.getDocumentationComment(field),
                visibility: .public, static: true, declarator: .let,
                name: Projection.toMemberName(field),
                initialValue: initializer)
        }
    }

    // Generate bitwise operators for flags enums.
    // We can't define them on the base protocol because
    // it would require importing that module to resolve the operators.
    if try enumDefinition.isFlags {
        writer.writeMarkComment("OptionSet and bitwise operators")

        writer.writeExtension(
                type: .identifier(structName),
                protocolConformances: [ .identifier("OptionSet") ]) { writer in
            // Bitwise not
            writer.writeFunc(
                    visibility: .public, static: true, operatorLocation: .prefix, name: "~",
                    params: [ .init(name: "value", type: .`self`) ],
                    returnType: .`self`) { writer in
                writer.writeStatement("Self(rawValue: ~value.rawValue)")
            }

            // Bitwise or, and, xor, including assignment forms
            for op in [ "|", "&", "^" ] {
                writer.writeFunc(
                        visibility: .public, static: true, name: op,
                        params: [ .init(name: "lhs", type: .`self`), .init(name: "rhs", type: .`self`) ],
                        returnType: .`self`) { writer in
                    writer.writeStatement("Self(rawValue: lhs.rawValue \(op) rhs.rawValue)")
                }

                writer.writeFunc(
                        visibility: .public, static: true, name: op + "=",
                        params: [ .init(name: "lhs", `inout`: true, type: .`self`), .init(name: "rhs", type: .`self`) ]) { writer in
                    writer.writeStatement("lhs = Self(rawValue: lhs.rawValue \(op) rhs.rawValue)")
                }
            }
        }
    }
}

fileprivate func writeClosedEnumDefinition(_ enumDefinition: EnumDefinition, projection: Projection, to writer: SwiftSourceFileWriter) throws {
    try writer.writeEnum(
            documentation: projection.getDocumentationComment(enumDefinition),
            visibility: Projection.toVisibility(enumDefinition.visibility),
            name: try projection.toTypeName(enumDefinition),
            rawValueType: try projection.toType(enumDefinition.underlyingType.bindNode()),
            protocolConformances: [ .identifier("ClosedEnum") ]) { writer throws in
        for field in enumDefinition.fields.filter({ $0.visibility == .public && $0.isStatic }) {
            try writer.writeEnumCase(
                documentation: projection.getDocumentationComment(field),
                name: Projection.toMemberName(field),
                rawValue: Projection.toConstant(try field.literalValue!))
        }
    }
}