import Collections
import DotNetMetadata
import WindowsMetadata
import ProjectionModel
import CodeWriters
import struct Foundation.UUID

/// Writes a type or extension providing the ABIBinding conformance for a given projected WinRT type.
internal func writeABIBindingConformance(_ typeDefinition: TypeDefinition, genericArgs: [TypeNode]?, projection: Projection, to writer: SwiftSourceFileWriter) throws {
    if let structDefinition = typeDefinition as? StructDefinition {
        assert(genericArgs == nil)
        try writeStructBindingExtension(structDefinition, projection: projection, to: writer)
        return
    }

    if let enumDefinition = typeDefinition as? EnumDefinition {
        assert(genericArgs == nil)
        try writeEnumBindingExtension(enumDefinition, projection: projection, to: writer)
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
            name: try projection.toBindingTypeName(typeDefinition),
            projection: projection, to: writer)
    }
    else if let genericArgs {
        // Generic type specialization. Create a projection for the specialization.
        // extension IVectorBinding {
        //     internal final class Boolean: WinRTBinding... {}
        // }
        try writer.writeExtension(
                attributes: [ projection.getAvailableAttribute(typeDefinition) ].compactMap { $0 },
                type: projection.toBindingType(typeDefinition)) { writer in
            try writeInterfaceOrDelegateBindingType(
                typeDefinition.bindType(genericArgs: genericArgs),
                name: try Projection.toBindingInstantiationTypeName(genericArgs: genericArgs),
                projection: projection, to: writer)
        }
    }
    else {
        // Generic type definition. Create a namespace for projections of specializations.
        // public enum IVectorBinding {}
        try writer.writeEnum(
            attributes: [ projection.getAvailableAttribute(typeDefinition) ].compactMap { $0 },
            visibility: Projection.toVisibility(typeDefinition.visibility),
            name: projection.toBindingTypeName(typeDefinition)) { _ in }
    }
}

/// Writes an extension to an enum to provide the ABIBinding conformance.
fileprivate func writeEnumBindingExtension(
        _ enumDefinition: EnumDefinition,
        projection: Projection,
        to writer: SwiftSourceFileWriter) throws {
    let enumBindingProtocol = try projection.isSwiftEnumEligible(enumDefinition)
        ? SupportModules.WinRT.closedEnumBinding : SupportModules.WinRT.openEnumBinding
    try writer.writeExtension(
            attributes: [ projection.getAvailableAttribute(enumDefinition) ].compactMap { $0 },
            type: projection.toTypeReference(enumDefinition.bindType()),
            protocolConformances: [ enumBindingProtocol ]) { writer in
        // public static var typeName: String { "..." }
        try writeTypeNameProperty(type: enumDefinition.bindType(), to: writer)

        // public static var ireferenceID: COM.COMInterfaceID { .init(...) }
        // public static var ireferenceArrayID: COM.COMInterfaceID { .init(...) }
        try writeIReferenceIDProperties(boxableType: enumDefinition.bindType(), to: writer)
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
            attributes: [ projection.getAvailableAttribute(structDefinition) ].compactMap { $0 },
            type: .named(projection.toTypeName(structDefinition)),
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
                        typeBinding: projection.getTypeBinding(field.type), to: output)
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
                        typeBinding: projection.getTypeBinding(field.type), to: output)
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
                    let typeBinding = try projection.getTypeBinding(field.type)
                    if typeBinding.kind == .allocating {
                        writer.writeStatement("\(typeBinding.bindingType).release(&value.\(field.name))")
                    }
                }
            }
        }
    }
}

fileprivate func writeStructABIToSwiftInitializerParam(
        abiValueName: String, abiFieldName: String, swiftFieldName: String,
        typeBinding: TypeBinding, to output: LineBasedTextOutputStream) throws {
    var output = output
    SwiftIdentifier.write(swiftFieldName, to: &output)
    output.write(": ")

    if typeBinding.kind != .identity {
        typeBinding.bindingType.write(to: &output)
        output.write(".fromABI(")
    }

    SwiftIdentifier.write(abiValueName, to: &output)
    output.write(".")
    SwiftIdentifier.write(abiFieldName, to: &output)

    if typeBinding.kind != .identity {
        output.write(")")
    }
}

fileprivate func writeStructSwiftToABIInitializerParam(
        swiftValueName: String, swiftFieldName: String, abiFieldName: String,
        typeBinding: TypeBinding, to output: LineBasedTextOutputStream) throws {
    var output = output
    SwiftIdentifier.write(abiFieldName, to: &output)
    output.write(": ")

    if typeBinding.kind != .identity {
        if typeBinding.kind != .pod { output.write("try ") }
        typeBinding.bindingType.write(to: &output)
        output.write(".toABI(")
    }

    SwiftIdentifier.write(swiftValueName, to: &output)
    output.write(".")
    SwiftIdentifier.write(swiftFieldName, to: &output)

    if typeBinding.kind != .identity {
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

    let bindingProtocol = try classDefinition.hasAttribute(ComposableAttribute.self)
        ? SupportModules.WinRT.composableClassBinding
        : SupportModules.WinRT.runtimeClassBinding

    // Runtimeclass bindings are classes so they can be found using NSClassFromString,
    // which allows supporting instantiating the most derived class wrapper when returned from WinRT. 
    try writer.writeClass(
            attributes: [ projection.getAvailableAttribute(classDefinition) ].compactMap { $0 },
            visibility: Projection.toVisibility(classDefinition.visibility),
            name: projection.toBindingTypeName(classDefinition),
            protocolConformances: [ bindingProtocol ]) { writer throws in
        try writeReferenceTypeBindingConformance(
            apiType: classDefinition.bindType(),
            abiType: defaultInterface.asBoundType,
            wrapImpl: { writer, paramName in
                writer.writeStatement(".init(_wrapping: consume \(paramName))")
            },
            projection: projection,
            to: writer)

        if !classDefinition.isSealed {
            try writeComposableClassOuterObject(classDefinition, projection: projection, to: writer)
        }
    }
}

fileprivate func writeComposableClassOuterObject(
        _ classDefinition: ClassDefinition,
        projection: Projection,
        to writer: SwiftTypeDefinitionWriter) throws {
    let outerObjectClassName = SupportModules.WinRT.composableClass_outerObject_shortName

    let baseOuterObjectClass: SwiftType
    if let base = try classDefinition.base, try base.definition.base != nil {
        baseOuterObjectClass = try projection.toBindingType(base.definition).member(outerObjectClassName)
    } else {
        baseOuterObjectClass = SupportModules.WinRT.composableClass_outerObject
    }

    let overridableInterfaces = try classDefinition.baseInterfaces.compactMap {
        try $0.hasAttribute(OverridableAttribute.self) ? $0.interface : nil
    }

    // If nothing to override:
    // public typealias OuterObject = SuperclassBinding.OuterObject
    guard !overridableInterfaces.isEmpty else {
        writer.writeTypeAlias(visibility: .public, name: outerObjectClassName, target: baseOuterObjectClass)
        return
    }

    try writer.writeClass(
            visibility: .open,
            name: outerObjectClassName,
            base: baseOuterObjectClass) { writer in

        // public override func _queryInterface(_ id: COM.COMInterfaceID) throws -> COM.IUnknownReference {
        try writer.writeFunc(
                visibility: .public, override: true, name: "_queryInterface",
                params: [ .init(label: "_", name: "id", type: SupportModules.COM.comInterfaceID) ], throws: true,
                returnType: SupportModules.COM.iunknownReference) { writer in
            for interface in overridableInterfaces {
                // if id == uuidof(SWRT_IFoo.self) {
                let abiSwiftType = try projection.toABIType(interface.asBoundType)
                writer.writeBracedBlock("if id == uuidof(\(abiSwiftType).self)") { writer in
                    let propertyName = SecondaryInterfaces.getPropertyName(interface)

                    // _ifoo.initOwner(owner as! MyClass)
                    // return _ifoo.toCOM()
                    writer.writeStatement("\(propertyName).initOwner(owner as! SwiftObject)")
                    writer.writeReturnStatement(value: "\(propertyName).toCOM()")
                }
            }

            writer.writeReturnStatement(value: "try super._queryInterface(id)")
        }

        for interface in overridableInterfaces {
            // private var _ifoo: COM.COMEmbedding = .init(virtualTable: &OuterObject.istringable, owner: nil)
            let vtablePropertyName = Casing.pascalToCamel(interface.definition.nameWithoutGenericArity)
            writer.writeStoredProperty(
                visibility: .private, declarator: .var,
                name: SecondaryInterfaces.getPropertyName(interface),
                type: SupportModules.COM.comEmbedding,
                initialValue: ".init(virtualTable: &\(outerObjectClassName).\(vtablePropertyName), owner: nil)")
        }

        for interface in overridableInterfaces {
            try writeVirtualTableProperty(
                visibility: .private,
                name: Casing.pascalToCamel(interface.definition.nameWithoutGenericArity),
                abiType: interface.asBoundType, swiftType: classDefinition.bindType(),
                projection: projection, to: writer)
        }
    }
}

fileprivate func writeInterfaceOrDelegateBindingType(
        _ type: BoundType,
        name: String,
        projection: Projection,
        to writer: some SwiftDeclarationWriter) throws {
    precondition(type.definition is InterfaceDefinition || type.definition is DelegateDefinition)
    let bindingProtocol = type.definition is InterfaceDefinition
        ? SupportModules.WinRT.interfaceBinding : SupportModules.WinRT.delegateBinding

    // Projections of generic instantiations are not owned by any specific module.
    // Making them internal avoids clashes between redundant definitions across modules.
    try writer.writeEnum(
            attributes: [ projection.getAvailableAttribute(type.definition) ].compactMap { $0 },
            visibility: type.genericArgs.isEmpty ? Projection.toVisibility(type.definition.visibility) : .internal,
            name: name,
            protocolConformances: [ bindingProtocol ]) { writer throws in

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
            type, visibility: .private, name: importClassName,
            bindingType: .named(name),
            projection: projection, to: writer)

        // public static var exportedVirtualTable: VirtualTablePointer { .init(&virtualTable) }
        writer.writeComputedProperty(
                visibility: .public, static: true, name: "exportedVirtualTable",
                type: SupportModules.COM.virtualTablePointer) { writer in
            writer.writeStatement(".init(&virtualTable)")
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
        target: try projection.toTypeReference(apiType))
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

    let abiReferenceType: SwiftType = .named("ABIReference")

    try writer.writeFunc(
            visibility: .public, static: true, name: "_wrap",
            params: [ .init(label: "_", name: "reference", consuming: true, type: abiReferenceType) ],
            returnType: .named("SwiftObject")) { writer in
        try wrapImpl(&writer, "reference")
    }

    if let toCOMImpl {
        try writer.writeFunc(
                visibility: .public, static: true, name: "toCOM",
                params: [ .init(label: "_", name: "object", escaping: abiType.definition is DelegateDefinition, type: .named("SwiftObject")) ],
                throws: true, returnType: abiReferenceType) { writer in
            try toCOMImpl(&writer, "object")
        }
    }
}