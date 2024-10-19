import Collections
import DotNetMetadata
import WindowsMetadata
import ProjectionModel
import CodeWriters
import struct Foundation.UUID

/// Writes a type or extension providing the ABIBinding conformance for a given projected WinRT type.
internal func writeABIBindingConformance(_ typeDefinition: TypeDefinition, genericArgs: [TypeNode]?, projection: Projection, to writer: SwiftSourceFileWriter) throws {
    if SupportModules.WinRT.getBuiltInTypeKind(typeDefinition) == .definitionAndBinding {
        // The support module already defines a projection, just import and reexport it.
        if typeDefinition.isReferenceType {
            let bindingTypeName = try projection.toBindingTypeName(typeDefinition)
            writer.writeImport(exported: true, kind: .enum, module: SupportModules.WinRT.moduleName, symbolName: bindingTypeName)
        }
        else {
            // The struct conforms to ABIBinding itself, and we already imported it.
        }
        return
    }

    if let structDefinition = typeDefinition as? StructDefinition {
        assert(genericArgs == nil)
        try writeStructBindingExtension(structDefinition, projection: projection, to: writer)
        return
    }

    if let enumDefinition = typeDefinition as? EnumDefinition {
        assert(genericArgs == nil)
        let enumBindingProtocol = try projection.isSwiftEnumEligible(enumDefinition)
            ? SupportModules.WinRT.closedEnumBinding : SupportModules.WinRT.openEnumBinding
        try writer.writeExtension(
                type: .identifier(projection.toTypeName(enumDefinition)),
                protocolConformances: [ enumBindingProtocol ]) { writer in
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
            try writeClassBindingType(classDefinition, defaultInterface: defaultInterface, projection: projection, to: writer)
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
        // enum IVectorBinding: WinRTBinding... {}
        try writeInterfaceOrDelegateBindingType(typeDefinition.bindType(),
            projectionName: try projection.toBindingTypeName(typeDefinition), projection: projection, to: writer)
    }
    else if let genericArgs {
        // Generic type specialization. Create a projection for the specialization.
        // extension IVectorBinding {
        //     internal final class Boolean: WinRTBinding... {}
        // }
        try writer.writeExtension(
                type: .identifier(projection.toBindingTypeName(typeDefinition))) { writer in
            try writeInterfaceOrDelegateBindingType(
                typeDefinition.bindType(genericArgs: genericArgs),
                projectionName: try Projection.toBindingInstantiationTypeName(genericArgs: genericArgs),
                projection: projection,
                to: writer)
        }
    }
    else {
        // Generic type definition. Create a namespace for projections of specializations.
        // public enum IVectorBinding {}
        try writer.writeEnum(
            visibility: Projection.toVisibility(typeDefinition.visibility),
            name: projection.toBindingTypeName(typeDefinition)) { _ in }
    }
}

/// Writes an extension to a struct to provide the ABIBinding conformance.
fileprivate func writeStructBindingExtension(
        _ structDefinition: StructDefinition,
        projection: Projection,
        to writer: SwiftSourceFileWriter) throws {
    let isPOD = try projection.isPODBinding(structDefinition)

    var protocolConformances = [SupportModules.WinRT.structBinding]
    if isPOD {
        protocolConformances.append(SupportModules.COM.abiPODBinding)
    }

    // extension <struct>: IReferenceableBinding[, PODBinding]
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

        // public static func fromABI(_ value: ABIValue) -> SwiftValue { .init(field: value.Field, ...) }
        try writer.writeFunc(
                visibility: .public, static: true, name: "fromABI",
                params: [.init(label: "_", name: "value", type: abiType)],
                returnType: .`self`) { writer in
            if fields.isEmpty {
                writer.writeStatement(".init()")
                return
            }

            let output = writer.output
            try output.writeLineBlock(header: ".init(") {
                for (index, field) in fields.enumerated() {
                    if index > 0 { output.write(",", endLine: true) }
                    try writeStructABIToSwiftInitializerParam(
                        abiValueName: "value", abiFieldName: field.name, swiftFieldName: Projection.toMemberName(field),
                        typeProjection: projection.getTypeBinding(field.type), to: output)
                }
            }
            output.write(")", endLine: true)
        }

        // public static func toABI(_ value: SwiftValue) -> ABIValue { .init(Field: value.field, ...) }
        try writer.writeFunc(
                visibility: .public, static: true, name: "toABI",
                params: [.init(label: "_", name: "value", type: .`self`)],
                throws: !isPOD,
                returnType: abiType) { writer in
            if fields.isEmpty {
                writer.writeStatement(".init()")
                return
            }

            let output = writer.output
            try output.writeLineBlock(header: ".init(") {
                for (index, field) in fields.enumerated() {
                    if index > 0 { output.write(",", endLine: true) }
                    try writeStructSwiftToABIInitializerParam(
                        swiftValueName: "value", swiftFieldName: Projection.toMemberName(field), abiFieldName: field.name,
                        typeProjection: projection.getTypeBinding(field.type), to: output)
                }
            }
            output.write(")", endLine: true)
        }

        if !isPOD {
            // public static func release(_ value: inout ABIValue) {}
            try writer.writeFunc(
                    visibility: .public, static: true, name: "release",
                    params: [.init(label: "_", name: "value", `inout`: true, type: abiType)]) { writer in
                for field in fields {
                    let typeProjection = try projection.getTypeBinding(field.type)
                    if typeProjection.kind == .allocating {
                        writer.writeStatement("\(typeProjection.bindingType).release(&value.\(field.name))")
                    }
                }
            }
        }
    }
}

fileprivate func writeStructABIToSwiftInitializerParam(
        abiValueName: String, abiFieldName: String, swiftFieldName: String,
        typeProjection: TypeProjection, to output: LineBasedTextOutputStream) throws {
    var output = output
    SwiftIdentifier.write(swiftFieldName, to: &output)
    output.write(": ")

    if typeProjection.kind != .identity {
        typeProjection.bindingType.write(to: &output)
        output.write(".fromABI(")
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
        typeProjection: TypeProjection, to output: LineBasedTextOutputStream) throws {
    var output = output
    SwiftIdentifier.write(abiFieldName, to: &output)
    output.write(": ")

    if typeProjection.kind != .identity {
        if typeProjection.kind != .pod { output.write("try ") }
        typeProjection.bindingType.write(to: &output)
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

/// Writes a type providing the ABIBinding conformance for a WinRT class.
fileprivate func writeClassBindingType(
        _ classDefinition: ClassDefinition,
        defaultInterface: BoundInterface,
        projection: Projection,
        to writer: SwiftSourceFileWriter) throws {
    assert(!classDefinition.isStatic)

    let projectionProtocol = try classDefinition.hasAttribute(ComposableAttribute.self)
        ? SupportModules.WinRT.composableClassBinding
        : SupportModules.WinRT.activatableClassBinding

    let bindingTypeName = try projection.toBindingTypeName(classDefinition)
    try writer.writeClass(
            visibility: Projection.toVisibility(classDefinition.visibility),
            name: bindingTypeName, protocolConformances: [ projectionProtocol ]) { writer throws in
        let typeName = try projection.toTypeName(classDefinition)

        try writeReferenceTypeBindingConformance(
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

fileprivate func writeInterfaceOrDelegateBindingType(
        _ type: BoundType,
        projectionName: String,
        projection: Projection,
        to writer: some SwiftDeclarationWriter) throws {
    precondition(type.definition is InterfaceDefinition || type.definition is DelegateDefinition)
    let projectionProtocol = type.definition is InterfaceDefinition
        ? SupportModules.WinRT.interfaceBinding : SupportModules.WinRT.delegateBinding

    // Projections of generic instantiations are not owned by any specific module.
    // Making them internal avoids clashes between redundant definitions across modules.
    try writer.writeEnum(
            visibility: type.genericArgs.isEmpty ? Projection.toVisibility(type.definition.visibility) : .internal,
            name: projectionName,
            protocolConformances: [ projectionProtocol ]) { writer throws in

        let importClassName = "Import"

        if type.definition is InterfaceDefinition {
            try writeReferenceTypeBindingConformance(
                apiType: type, abiType: type,
                wrapImpl: { writer, paramName in
                    writer.writeStatement("\(importClassName)(_wrapping: consume \(paramName))")
                },
                projection: projection,
                to: writer)
        }
        else {
            assert(type.definition is DelegateDefinition)
            try writeReferenceTypeBindingConformance(
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

/// Writes members implementing the COMBinding or WinRTBinding protocol
internal func writeReferenceTypeBindingConformance(
        apiType: BoundType, abiType: BoundType,
        wrapImpl: (_ writer: inout SwiftStatementWriter, _ paramName: String) throws -> Void,
        toCOMImpl: ((_ writer: inout SwiftStatementWriter, _ paramName: String) throws -> Void)? = nil,
        projection: Projection,
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