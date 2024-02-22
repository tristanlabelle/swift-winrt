import Collections
import DotNetMetadata
import WindowsMetadata
import ProjectionModel
import CodeWriters
import struct Foundation.UUID

internal func writeABIProjectionsFile(module: SwiftProjection.Module, toPath path: String) throws {
    let writer = SwiftSourceFileWriter(output: FileTextOutputStream(path: path, directoryCreation: .ancestors))
    writeGeneratedCodePreamble(to: writer)
    writeModulePreamble(module, to: writer)

    for (_, typeDefinitions) in module.typeDefinitionsByNamespace {
        for typeDefinition in typeDefinitions.sorted(by: { $0.fullName < $1.fullName }) {
            guard typeDefinition.isPublic,
                !SupportModule.hasBuiltInProjection(typeDefinition),
                try !typeDefinition.hasAttribute(ApiContractAttribute.self) else { continue }

            try writeABIProjectionConformance(typeDefinition, genericArgs: nil, projection: module.projection, to: writer)
        }
    }

    let closedGenericTypesByDefinition = module.closedGenericTypesByDefinition
        .sorted { $0.key.fullName < $1.key.fullName }
    for (typeDefinition, instantiations) in closedGenericTypesByDefinition {
        guard !SupportModule.hasBuiltInProjection(typeDefinition) else { continue }

        for genericArgs in instantiations {
            try writeABIProjectionConformance(typeDefinition, genericArgs: genericArgs, projection: module.projection, to: writer)
        }
    }
}

/// Writes a type or extension providing the ABIProjection conformance for a given projected WinRT type.
internal func writeABIProjectionConformance(_ typeDefinition: TypeDefinition, genericArgs: [TypeNode]?, projection: SwiftProjection, to writer: SwiftSourceFileWriter) throws {
    if let structDefinition = typeDefinition as? StructDefinition {
        assert(genericArgs == nil)
        try writeStructProjectionExtension(structDefinition, projection: projection, to: writer)
        return
    }

    if let enumDefinition = typeDefinition as? EnumDefinition {
        assert(genericArgs == nil)
        try writer.writeExtension(
            name: projection.toTypeName(enumDefinition),
            protocolConformances: [SwiftType.chain("WindowsRuntime", "IntegerEnumProjection")]) { _ in }
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
                name: projection.toProjectionTypeName(typeDefinition)) { writer in
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
    let abiType = SwiftType.chain(projection.abiModuleName, try CAbi.mangleName(type: structDefinition.bindType()))

    // TODO: Support strings and IReference<T> field types (non-inert)
    // extension <struct>: ABIInertProjection
    try writer.writeExtension(
            name: try projection.toTypeName(structDefinition),
            protocolConformances: [SupportModule.abiInertProjection]) { writer in

        // public typealias SwiftValue = Self
        writer.writeTypeAlias(visibility: .public, name: "SwiftValue", target: .`self`)

        // public typealias ABIValue = <abi-type>
        writer.writeTypeAlias(visibility: .public, name: "ABIValue", target: abiType)

        // public static var abiDefaultValue: ABIValue { .init() }
        writer.writeComputedProperty(
                visibility: .public, static: true, name: "abiDefaultValue", type: abiType) { writer in
            writer.writeStatement(".init()")
        }

        // public static func toSwift(_ value: ABIValue) -> SwiftValue { .init(field: value.Field, ...) }
        try writer.writeFunc(
                visibility: .public, static: true, name: "toSwift",
                params: [.init(label: "_", name: "value", type: abiType)], 
                returnType: .`self`) { writer in
            var expression = ".init("
            for (index, field) in structDefinition.fields.enumerated() {
                guard field.isInstance else { continue }
                if index > 0 { expression += ", " }

                SwiftIdentifier.write(SwiftProjection.toMemberName(field), to: &expression)
                expression += ": "

                let typeProjection = try projection.getTypeProjection(field.type)
                if typeProjection.kind == .identity {
                    expression += "value."
                    SwiftIdentifier.write(field.name, to: &expression)
                }
                else {
                    typeProjection.projectionType.write(to: &expression)
                    expression += ".toSwift("
                    expression += "value."
                    SwiftIdentifier.write(field.name, to: &expression)
                    expression += ")"
                }
            }
            expression += ")"
            writer.writeStatement(expression)
        }

        // public static func toABI(_ value: SwiftValue) -> ABIValue { .init(Field: value.field, ...) }
        try writer.writeFunc(
                visibility: .public, static: true, name: "toABI",
                params: [.init(label: "_", name: "value", type: .`self`)],
                returnType: abiType) { writer in
            var expression = ".init("
            for (index, field) in structDefinition.fields.enumerated() {
                guard field.isInstance else { continue }
                if index > 0 { expression += ", " }

                SwiftIdentifier.write(field.name, to: &expression)
                expression += ": "

                let typeProjection = try projection.getTypeProjection(field.type)
                if typeProjection.kind == .identity {
                    expression += "value."
                    SwiftIdentifier.write(SwiftProjection.toMemberName(field), to: &expression)
                }
                else {
                    if typeProjection.kind != .inert { expression.append("try! ") }
                    typeProjection.projectionType.write(to: &expression)
                    expression += ".toABI("
                    expression += "value."
                    SwiftIdentifier.write(SwiftProjection.toMemberName(field), to: &expression)
                    expression += ")"
                }
            }
            expression += ")"
            writer.writeStatement(expression)
        }
    }
}

/// Writes a type providing the ABIProjection conformance for a WinRT class.
fileprivate func writeClassProjectionType(
        _ classDefinition: ClassDefinition,
        defaultInterface: BoundInterface,
        projection: SwiftProjection,
        to writer: SwiftSourceFileWriter) throws {
    assert(!classDefinition.isStatic)

    let projectionTypeName = try projection.toProjectionTypeName(classDefinition)
    try writer.writeEnum(
            visibility: SwiftProjection.toVisibility(classDefinition.visibility),
            name: projectionTypeName, protocolConformances: [ .identifier("WinRTProjection") ]) { writer throws in
        let typeName = try projection.toTypeName(classDefinition)
        let composable = try classDefinition.hasAttribute(ComposableAttribute.self)

        try writeCOMProjectionConformance(
            apiType: classDefinition.bindType(),
            abiType: defaultInterface.asBoundType,
            toSwiftBody: { writer, paramName in
                // Sealed classes are always created by WinRT, so don't need unwrapping
                writer.writeStatement("\(typeName)(_transferringRef: \(paramName))")
            },
            toCOMBody: { writer, paramName in
                if composable {
                    let lazyComputedPropertyName = getSecondaryInterfaceLazyComputedPropertyName(defaultInterface.definition)
                    writer.writeStatement("IUnknownPointer.addingRef(try object.\(lazyComputedPropertyName).this)")
                }
                else {
                    // WinRTImport exposes comPointer
                    writer.writeStatement("IUnknownPointer.addingRef(object._pointer)")
                }
            },
            projection: projection,
            to: writer)
    }
}

fileprivate func writeInterfaceOrDelegateProjectionType(
        _ type: BoundType,
        projectionName: String,
        projection: SwiftProjection,
        to writer: some SwiftDeclarationWriter) throws {
    precondition(type.definition is InterfaceDefinition || type.definition is DelegateDefinition)
    let projectionProtocolName = type.definition is InterfaceDefinition ? "WinRTTwoWayProjection" : "COMTwoWayProjection"

    try writer.writeEnum(
            visibility: SwiftProjection.toVisibility(type.definition.visibility),
            name: projectionName,
            protocolConformances: [ .identifier(projectionProtocolName) ]) { writer throws in

        let importClassName = "Import"

        try writeCOMProjectionConformance(
            apiType: type, abiType: type,
            toSwiftBody: { writer, paramName in
                if type.definition is InterfaceDefinition {
                    // Let COMImport attempt unwrapping first
                    writer.writeStatement("\(importClassName).toSwift(transferringRef: \(paramName))")
                }
                else {
                    // Delegates have no identity so cannot be unwrapped
                    writer.writeStatement("\(importClassName)(_transferringRef: \(paramName)).invoke")
                }
            },
            toCOMBody: { writer, paramName in
                if type.definition is InterfaceDefinition {
                    // Interfaces might be SwiftObjects or previous COMImports
                    writer.writeStatement("try \(importClassName).toCOM(\(paramName))")
                }
                else {
                    // Delegates have no identity, so create one for them
                    writer.writeStatement("COMWrappingExport<Self>(implementation: \(paramName)).toCOM()")
                }
            },
            projection: projection,
            to: writer)

        try writeCOMImportClass(
            type, visibility: .private, name: importClassName, projectionName: projectionName,
            projection: projection, to: writer)

        // public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &virtualTable) { $0 } }
        // private static var virtualTable = COMVirtualTable(...)
        writer.writeComputedProperty(
                visibility: .public, static: true, name: "virtualTablePointer",
                type: .identifier("COMVirtualTablePointer")) { writer in
            writer.writeStatement("withUnsafePointer(to: &virtualTable) { $0 }")
        }

        try writer.writeStoredProperty(
            visibility: .private, static: true, declarator: .var, name: "virtualTable",
            initializer: { try writeVirtualTable(interfaceOrDelegate: type, projection: projection, to: $0) })
    }
}

/// Writes members implementing the COMProjection or WinRTProjection protocol
internal func writeCOMProjectionConformance(
        apiType: BoundType, abiType: BoundType,
        toSwiftBody: (_ writer: inout SwiftStatementWriter, _ paramName: String) throws -> Void,
        toCOMBody: (_ writer: inout SwiftStatementWriter, _ paramName: String) throws -> Void,
        projection: SwiftProjection,
        to writer: SwiftTypeDefinitionWriter) throws {
    let abiName = try CAbi.mangleName(type: abiType)

    writer.writeTypeAlias(visibility: .public, name: "SwiftObject",
        target: try projection.toType(apiType.asNode).unwrapOptional())
    writer.writeTypeAlias(visibility: .public, name: "COMInterface",
        target: .chain(projection.abiModuleName, abiName))
    writer.writeTypeAlias(visibility: .public, name: "COMVirtualTable",
        target: .chain(projection.abiModuleName, abiName + CAbi.virtualTableSuffix))

    // public static var id: COM.COMInterfaceID { COM.COMInterop<COMInterface>.iid }
    writer.writeComputedProperty(visibility: .public, static: true, name: "id", type: SupportModule.comInterfaceID) { writer in
        let comInterop = SupportModule.comInterop(of: .identifier("COMInterface"))
        writer.writeStatement("\(comInterop).iid")
    }

    if !(abiType.definition is DelegateDefinition) {
        // Delegates are IUnknown whereas interfaces are IInspectable
        let runtimeClassName = try WinRTTypeName.from(type: apiType).description
        writer.writeStoredProperty(visibility: .public, static: true, declarator: .let, name: "runtimeClassName",
            initialValue: "\"\(runtimeClassName)\"")
    }

    try writer.writeFunc(
            visibility: .public, static: true, name: "toSwift",
            params: [ .init(label: "transferringRef", name: "comPointer", type: .identifier("COMPointer")) ],
            returnType: .identifier("SwiftObject")) { writer in
        try toSwiftBody(&writer, "comPointer")
    }

    try writer.writeFunc(
            visibility: .public, static: true, name: "toCOM",
            params: [ .init(label: "_", name: "object", escaping: abiType.definition is DelegateDefinition, type: .identifier("SwiftObject")) ],
            throws: true, returnType: .identifier("COMPointer")) { writer in
        try toCOMBody(&writer, "object")
    }
}