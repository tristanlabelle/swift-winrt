import Collections
import DotNetMetadata
import WindowsMetadata
import ProjectionModel
import CodeWriters
import struct Foundation.UUID

/// Writes a type or extension providing the ABIProjection conformance for a given projected WinRT type.
internal func writeABIProjectionConformance(_ typeDefinition: TypeDefinition, genericArgs: [TypeNode]?, projection: SwiftProjection, to writer: SwiftSourceFileWriter) throws {
    if SupportModules.WinRT.getBuiltInTypeKind(typeDefinition) == .definitionAndProjection {
        // The support module already defines a projection, just import and reexport it.
        if typeDefinition.isReferenceType {
            let projectionTypeName = try projection.toProjectionTypeName(typeDefinition)
            writer.writeImport(exported: true, kind: .enum, module: SupportModules.WinRT.moduleName, symbolName: projectionTypeName)
        }
        else {
            // The struct conforms to ABIProjection itself, and we already imported it.
        }
        return
    }

    if let structDefinition = typeDefinition as? StructDefinition {
        assert(genericArgs == nil)
        try writeStructProjectionExtension(structDefinition, projection: projection, to: writer)
        return
    }

    if let enumDefinition = typeDefinition as? EnumDefinition {
        assert(genericArgs == nil)
        let enumProjectionProtocol = try projection.isSwiftEnumEligible(enumDefinition)
            ? SupportModules.WinRT.closedEnumProjection : SupportModules.WinRT.openEnumProjection
        try writer.writeExtension(
                type: .identifier(projection.toTypeName(enumDefinition)),
                protocolConformances: [ enumProjectionProtocol ]) { writer in
            // public static var typeName: String { "..." }
            try writeTypeNameProperty(type: enumDefinition.bindType(), to: writer)

            // public static var ireferenceID: COM.COMInterfaceID { .init(...) }
            // public static var ireferenceArrayID: COM.COMInterfaceID { .init(...) }
            try writeIReferenceIDProperties(boxableType: enumDefinition.bindType(), to: writer)
        }
        return
    }

    if let classDefinition = typeDefinition as? ClassDefinition {
        assert(genericArgs == nil)
        if let defaultInterface = try DefaultAttribute.getDefaultInterface(classDefinition) {
            try writeClassProjectionType(classDefinition, defaultInterface: defaultInterface, projection: projection, to: writer)
        }
        else {
            // Static classes have no ABI-representable values to be projected.
            assert(classDefinition.isStatic)
        }
        return
    }

    // Interface, delegate or activatable class
    if typeDefinition.genericArity == 0 {
        // Non-generic type, create a standard projection type.
        // enum IVectorProjection: WinRTProjection... {}
        try writeInterfaceOrDelegateProjectionType(typeDefinition.bindType(),
            projectionName: try projection.toProjectionTypeName(typeDefinition), projection: projection, to: writer)
    }
    else if let genericArgs {
        // Generic type specialization. Create a projection for the specialization.
        // extension IVectorProjection {
        //     internal final class Boolean: WinRTProjection... {}
        // }
        try writer.writeExtension(
                type: .identifier(projection.toProjectionTypeName(typeDefinition))) { writer in
            try writeInterfaceOrDelegateProjectionType(
                typeDefinition.bindType(genericArgs: genericArgs),
                projectionName: try SwiftProjection.toProjectionInstantiationTypeName(genericArgs: genericArgs),
                projection: projection,
                to: writer)
        }
    }
    else {
        // Generic type definition. Create a namespace for projections of specializations.
        // public enum IVectorProjection {}
        try writer.writeEnum(
            visibility: SwiftProjection.toVisibility(typeDefinition.visibility),
            name: projection.toProjectionTypeName(typeDefinition)) { _ in }
    }
}

/// Writes an extension to a struct to provide the ABIProjection conformance.
fileprivate func writeStructProjectionExtension(
        _ structDefinition: StructDefinition,
        projection: SwiftProjection,
        to writer: SwiftSourceFileWriter) throws {
    let isInert = try projection.isProjectionInert(structDefinition)

    var protocolConformances = [SupportModules.WinRT.structProjection]
    if isInert {
        protocolConformances.append(SupportModules.COM.abiInertProjection)
    }

    // extension <struct>: IReferenceableProjection[, ABIInertProjection]
    try writer.writeExtension(
            type: .identifier(projection.toTypeName(structDefinition)),
            protocolConformances: protocolConformances) { writer in

        let abiType = try projection.toABIType(structDefinition.bindType())

        // public typealias SwiftValue = Self
        writer.writeTypeAlias(visibility: .public, name: "SwiftValue", target: .`self`)

        // public typealias ABIValue = <abi-type>
        writer.writeTypeAlias(visibility: .public, name: "ABIValue", target: abiType)

        // public static var typeName: String { "..." }
        try writeTypeNameProperty(type: structDefinition.bindType(), to: writer)

        // public static var ireferenceID: COM.COMInterfaceID { .init(...) }
        // public static var ireferenceArrayID: COM.COMInterfaceID { .init(...) }
        try writeIReferenceIDProperties(boxableType: structDefinition.bindType(), to: writer)

        // public static var abiDefaultValue: ABIValue { .init() }
        writer.writeComputedProperty(
                visibility: .public, static: true, name: "abiDefaultValue", type: abiType) { writer in
            writer.writeStatement(".init()")
        }

        let fields = structDefinition.fields.filter { $0.isInstance }

        // public static func toSwift(_ value: ABIValue) -> SwiftValue { .init(field: value.Field, ...) }
        try writer.writeFunc(
                visibility: .public, static: true, name: "toSwift",
                params: [.init(label: "_", name: "value", type: abiType)],
                returnType: .`self`) { writer in
            if fields.isEmpty {
                writer.writeStatement(".init()")
                return
            }

            let output = writer.output
            try output.writeIndentedBlock(header: ".init(") {
                for (index, field) in fields.enumerated() {
                    if index > 0 { output.write(",", endLine: true) }
                    try writeStructABIToSwiftInitializerParam(
                        abiValueName: "value", abiFieldName: field.name, swiftFieldName: SwiftProjection.toMemberName(field),
                        typeProjection: projection.getTypeProjection(field.type), to: output)
                }
            }
            output.write(")", endLine: true)
        }

        // public static func toABI(_ value: SwiftValue) -> ABIValue { .init(Field: value.field, ...) }
        try writer.writeFunc(
                visibility: .public, static: true, name: "toABI",
                params: [.init(label: "_", name: "value", type: .`self`)],
                throws: !isInert,
                returnType: abiType) { writer in
            if fields.isEmpty {
                writer.writeStatement(".init()")
                return
            }

            let output = writer.output
            try output.writeIndentedBlock(header: ".init(") {
                for (index, field) in fields.enumerated() {
                    if index > 0 { output.write(",", endLine: true) }
                    try writeStructSwiftToABIInitializerParam(
                        swiftValueName: "value", swiftFieldName: SwiftProjection.toMemberName(field), abiFieldName: field.name,
                        typeProjection: projection.getTypeProjection(field.type), to: output)
                }
            }
            output.write(")", endLine: true)
        }

        if !isInert {
            // public static func release(_ value: inout ABIValue) {}
            try writer.writeFunc(
                    visibility: .public, static: true, name: "release",
                    params: [.init(label: "_", name: "value", `inout`: true, type: abiType)]) { writer in
                for field in fields {
                    let typeProjection = try projection.getTypeProjection(field.type)
                    if typeProjection.kind == .allocating {
                        writer.writeStatement("\(typeProjection.projectionType).release(&value.\(field.name))")
                    }
                }
            }
        }
    }
}

fileprivate func writeStructABIToSwiftInitializerParam(
        abiValueName: String, abiFieldName: String, swiftFieldName: String,
        typeProjection: TypeProjection, to output: IndentedTextOutputStream) throws {
    var output = output
    SwiftIdentifier.write(swiftFieldName, to: &output)
    output.write(": ")

    if typeProjection.kind != .identity {
        typeProjection.projectionType.write(to: &output)
        output.write(".toSwift(")
    }

    SwiftIdentifier.write(abiValueName, to: &output)
    output.write(".")
    SwiftIdentifier.write(abiFieldName, to: &output)

    if typeProjection.kind != .identity {
        output.write(")")
    }
}

fileprivate func writeStructSwiftToABIInitializerParam(
        swiftValueName: String, swiftFieldName: String, abiFieldName: String,
        typeProjection: TypeProjection, to output: IndentedTextOutputStream) throws {
    var output = output
    SwiftIdentifier.write(abiFieldName, to: &output)
    output.write(": ")

    if typeProjection.kind != .identity {
        if typeProjection.kind != .inert { output.write("try ") }
        typeProjection.projectionType.write(to: &output)
        output.write(".toABI(")
    }

    SwiftIdentifier.write(swiftValueName, to: &output)
    output.write(".")
    SwiftIdentifier.write(swiftFieldName, to: &output)

    if typeProjection.kind != .identity {
        output.write(")")
    }
}

fileprivate func writeIReferenceIDProperties(boxableType: BoundType, to writer: SwiftTypeDefinitionWriter) throws {
    // public static var ireferenceID: COM.COMInterfaceID { UUID(...) }
    try writeIReferenceIDProperty(
        propertyName: "ireferenceID", parameterizedID: UUID(uuidString: "61c17706-2d65-11e0-9ae8-d48564015472")!,
        boxableType: boxableType, to: writer)
    // public static var ireferenceArrayID: COM.COMInterfaceID { UUID(...) }
    try writeIReferenceIDProperty(
        propertyName: "ireferenceArrayID", parameterizedID: UUID(uuidString: "61c17707-2d65-11e0-9ae8-d48564015472")!,
        boxableType: boxableType, to: writer)
}

fileprivate func writeIReferenceIDProperty(propertyName: String, parameterizedID: UUID, boxableType: BoundType, to writer: SwiftTypeDefinitionWriter) throws {
    try writer.writeComputedProperty(visibility: .public, static: true, name: propertyName, type: SupportModules.COM.comInterfaceID) { writer in
        let typeSignature = try WinRTTypeSignature.interface(
            id: parameterizedID,
            args: [ WinRTTypeSignature(boxableType) ])
        writer.writeStatement(try toIIDExpression(typeSignature.parameterizedID))
    }
}

/// Writes a type providing the ABIProjection conformance for a WinRT class.
fileprivate func writeClassProjectionType(
        _ classDefinition: ClassDefinition,
        defaultInterface: BoundInterface,
        projection: SwiftProjection,
        to writer: SwiftSourceFileWriter) throws {
    assert(!classDefinition.isStatic)

    let projectionProtocol = try classDefinition.hasAttribute(ComposableAttribute.self)
        ? SupportModules.WinRT.composableClassProjection
        : SupportModules.WinRT.activatableClassProjection

    let projectionTypeName = try projection.toProjectionTypeName(classDefinition)
    try writer.writeClass(
            visibility: SwiftProjection.toVisibility(classDefinition.visibility),
            name: projectionTypeName, protocolConformances: [ projectionProtocol ]) { writer throws in
        let typeName = try projection.toTypeName(classDefinition)

        try writeReferenceTypeProjectionConformance(
            apiType: classDefinition.bindType(),
            abiType: defaultInterface.asBoundType,
            wrapImpl: { writer, paramName in
                writer.writeStatement("\(typeName)(_wrapping: consume \(paramName))")
            },
            projection: projection,
            to: writer)

        let overridableInterfaces = try classDefinition.baseInterfaces.compactMap {
            try $0.hasAttribute(OverridableAttribute.self) ? $0.interface : nil
        }
        if !overridableInterfaces.isEmpty {
            try writer.writeEnum(visibility: .internal, name: "VirtualTables") { writer in
                for interface in overridableInterfaces {
                    try writeVirtualTableProperty(
                        visibility: .internal,
                        name: Casing.pascalToCamel(interface.definition.nameWithoutGenericArity),
                        abiType: interface.asBoundType, swiftType: classDefinition.bindType(),
                        projection: projection, to: writer)
                }
            }
        }
    }
}

fileprivate func writeInterfaceOrDelegateProjectionType(
        _ type: BoundType,
        projectionName: String,
        projection: SwiftProjection,
        to writer: some SwiftDeclarationWriter) throws {
    precondition(type.definition is InterfaceDefinition || type.definition is DelegateDefinition)
    let projectionProtocol = type.definition is InterfaceDefinition
        ? SupportModules.WinRT.interfaceProjection : SupportModules.WinRT.delegateProjection

    // Projections of generic instantiations are not owned by any specific module.
    // Making them internal avoids clashes between redundant definitions across modules.
    try writer.writeEnum(
            visibility: type.genericArgs.isEmpty ? SwiftProjection.toVisibility(type.definition.visibility) : .internal,
            name: projectionName,
            protocolConformances: [ projectionProtocol ]) { writer throws in

        let importClassName = "Import"

        if type.definition is InterfaceDefinition {
            try writeReferenceTypeProjectionConformance(
                apiType: type, abiType: type,
                wrapImpl: { writer, paramName in
                    writer.writeStatement("\(importClassName)(_wrapping: consume \(paramName))")
                },
                projection: projection,
                to: writer)
        }
        else {
            assert(type.definition is DelegateDefinition)
            try writeReferenceTypeProjectionConformance(
                apiType: type, abiType: type,
                wrapImpl: { writer, paramName in
                    writer.writeStatement("\(importClassName)(_wrapping: consume \(paramName)).invoke")
                },
                toCOMImpl: { writer, paramName in
                    // Delegates have no identity, so create one for them
                    writer.writeStatement("ExportedDelegate<Self>(\(paramName)).toCOM()")
                },
                projection: projection,
                to: writer)
        }

        try writeCOMImportClass(
            type, visibility: .private, name: importClassName, projectionName: projectionName,
            projection: projection, to: writer)

        // public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }
        writer.writeComputedProperty(
                visibility: .public, static: true, name: "virtualTablePointer",
                type: .identifier("UnsafeRawPointer")) { writer in
            writer.writeStatement(".init(withUnsafePointer(to: &virtualTable) { $0 })")
        }

        // private static var virtualTable = SWRT_IFoo_VirtualTable(...)
        try writeVirtualTableProperty(name: "virtualTable", abiType: type, swiftType: type, projection: projection, to: writer)
    }
}

internal func writeTypeNameProperty(type: BoundType, to writer: SwiftTypeDefinitionWriter) throws {
    let typeName = try WinRTTypeName.from(type: type).description
    writer.writeStoredProperty(visibility: .public, static: true, declarator: .let, name: "typeName",
        initialValue: "\"\(typeName)\"")
}

/// Writes members implementing the COMProjection or WinRTProjection protocol
internal func writeReferenceTypeProjectionConformance(
        apiType: BoundType, abiType: BoundType,
        wrapImpl: (_ writer: inout SwiftStatementWriter, _ paramName: String) throws -> Void,
        toCOMImpl: ((_ writer: inout SwiftStatementWriter, _ paramName: String) throws -> Void)? = nil,
        projection: SwiftProjection,
        to writer: SwiftTypeDefinitionWriter) throws {
    writer.writeTypeAlias(visibility: .public, name: "SwiftObject",
        target: try projection.toType(apiType.asNode).unwrapOptional())
    writer.writeTypeAlias(visibility: .public, name: "ABIStruct",
        target: try projection.toABIType(abiType))

    // public static var typeName: String { "..." }
    try writeTypeNameProperty(type: apiType, to: writer)

    // public static var interfaceID: COM.COMInterfaceID { uuidof(ABIStruct.self) }
    writer.writeComputedProperty(visibility: .public, static: true, name: "interfaceID", type: SupportModules.COM.comInterfaceID) { writer in
        writer.writeStatement("uuidof(ABIStruct.self)")
    }

    if apiType.definition is DelegateDefinition {
        // Delegates can be boxed to IReference<T>
        // public static var ireferenceID: COM.COMInterfaceID { .init(...) }
        // public static var ireferenceArrayID: COM.COMInterfaceID { .init(...) }
        try writeIReferenceIDProperties(boxableType: apiType, to: writer)
    }

    let abiReferenceType = SwiftType.identifier("ABIReference")

    try writer.writeFunc(
            visibility: .public, static: true, name: "_wrap",
            params: [ .init(label: "_", name: "reference", consuming: true, type: abiReferenceType) ],
            returnType: .identifier("SwiftObject")) { writer in
        try wrapImpl(&writer, "reference")
    }

    if let toCOMImpl {
        try writer.writeFunc(
                visibility: .public, static: true, name: "toCOM",
                params: [ .init(label: "_", name: "object", escaping: abiType.definition is DelegateDefinition, type: .identifier("SwiftObject")) ],
                throws: true, returnType: abiReferenceType) { writer in
            try toCOMImpl(&writer, "object")
        }
    }
}