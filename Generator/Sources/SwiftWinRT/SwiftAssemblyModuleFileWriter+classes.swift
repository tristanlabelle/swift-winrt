import CodeWriters
import Collections
import DotNetMetadata
import WindowsMetadata
import struct Foundation.UUID

extension SwiftAssemblyModuleFileWriter {
    internal func writeClass(_ classDefinition: ClassDefinition) throws {
        try sourceFileWriter.writeClass(
                visibility: SwiftProjection.toVisibility(classDefinition.visibility, inheritableClass: !classDefinition.isSealed),
                final: classDefinition.isSealed,
                name: projection.toTypeName(classDefinition),
                typeParameters: classDefinition.genericParams.map { $0.name },
                base: projection.toBaseType(classDefinition.base),
                protocolConformances: classDefinition.baseInterfaces.compactMap { try projection.toBaseType($0.interface.asBoundType) }) { writer throws in
            try writeTypeAliasesForBaseGenericArgs(of: classDefinition, to: writer)
            try writeClassMembers(classDefinition, to: writer)
        }
    }

    fileprivate func writeTypeAliasesForBaseGenericArgs(of typeDefinition: TypeDefinition, to writer: SwiftTypeDefinitionWriter) throws {
        var baseTypes = try typeDefinition.baseInterfaces.map { try $0.interface.asBoundType }
        if let base = try typeDefinition.base {
            baseTypes.insert(base, at: 0)
        }

        var typeAliases: Collections.OrderedDictionary<String, SwiftType> = .init()
        for baseType in baseTypes {
            for (i, genericArg) in baseType.genericArgs.enumerated() {
                typeAliases[baseType.definition.genericParams[i].name] = try projection.toType(genericArg)
            }
        }

        for entry in typeAliases {
            writer.writeTypeAlias(visibility: .public, name: entry.key, typeParameters: [], target: entry.value)
        }
    }

    fileprivate func writeClassMembers(_ classDefinition: ClassDefinition, to writer: SwiftTypeDefinitionWriter) throws {
        for property in classDefinition.properties {
            if let getter = try property.getter, getter.isPublic {
                try writer.writeComputedProperty(
                    visibility: .public,
                    static: property.isStatic,
                    override: getter.isOverride,
                    name: projection.toMemberName(property),
                    type: projection.toReturnType(property.type),
                    throws: true,
                    get: { $0.writeNotImplemented() },
                    set: nil)
            }

            if let setter = try property.setter, setter.isPublic {
                // Swift does not support throwing setters, so generate a method
                try writer.writeFunc(
                    visibility: .public,
                    static: property.isStatic,
                    override: setter.isOverride,
                    name: projection.toMemberName(property),
                    parameters: [.init(label: "_", name: "newValue", type: projection.toType(property.type))],
                    throws: true) { $0.writeNotImplemented() }
            }
        }

        for method in classDefinition.methods {
            guard SwiftProjection.toVisibility(method.visibility) == .public else { continue }
            guard method.nameKind == .regular else { continue }
            if let constructor = method as? Constructor {
                try writer.writeInit(
                    visibility: .public,
                    override: try projection.isOverriding(constructor),
                    parameters: method.params.map { try projection.toParameter($0) },
                    throws: true) { $0.writeNotImplemented() }
            }
            else {
                try writer.writeFunc(
                    visibility: .public,
                    static: method.isStatic,
                    override: method.isOverride,
                    name: projection.toMemberName(method),
                    typeParameters: method.genericParams.map { $0.name },
                    parameters: method.params.map { try projection.toParameter($0) },
                    throws: true,
                    returnType: projection.toReturnTypeUnlessVoid(method.returnType)) { $0.writeNotImplemented() }
            }
        }
    }

    internal func writeClassProjection(_ classDefinition: ClassDefinition) throws {
        let typeName = try projection.toTypeName(classDefinition)
        if classDefinition.isAbstract && classDefinition.isSealed {
            // Static class
            assert(classDefinition.baseInterfaces.isEmpty)
            try sourceFileWriter.writeEnum(
                visibility: SwiftProjection.toVisibility(classDefinition.visibility),
                name: typeName) { try writeClassBody(classDefinition, to: $0) }
        }
        else {
            let protocolConformances: [SwiftType] = try [.identifier("WinRTProjection")]
                + classDefinition.baseInterfaces.map { .identifier(try projection.toProtocolName($0.interface.definition)) }
            try sourceFileWriter.writeClass(
                visibility: SwiftProjection.toVisibility(classDefinition.visibility), final: true, name: typeName,
                base: .identifier(name: "WinRTProjectionBase", genericArgs: [.identifier(name: typeName)]),
                protocolConformances: protocolConformances) { try writeClassBody(classDefinition, to: $0) }
        }
    }

    fileprivate func writeClassBody(_ classDefinition: ClassDefinition, to writer: SwiftTypeDefinitionWriter) throws {
        if let defaultInterface = try DefaultAttribute.getDefaultInterface(classDefinition) {
            try writeWinRTProjectionConformance(
                interfaceOrDelegate: defaultInterface.asBoundType, classDefinition: classDefinition, to: writer)
        }

        try writeGenericTypeAliases(interfaces: classDefinition.baseInterfaces.map { try $0.interface }, to: writer)

        try writeInterfaceImplementations(classDefinition.bindType(), to: writer)

        // Write initializers from activation factories
        for activatableAttribute in try classDefinition.getAttributes(ActivatableAttribute.self) {
            if activatableAttribute.factory == nil {
                try writeDefaultInitializer(classDefinition, to: writer)
            }
        }

        // Write static members from static interfaces
        for staticAttribute in try classDefinition.getAttributes(StaticAttribute.self) {
            let interfaceProperty = try writeSecondaryInterfaceProperty(
                staticAttribute.interface.bind(), staticOf: classDefinition, to: writer)
            try writeMemberImplementations(
                interfaceOrDelegate: staticAttribute.interface.bindType(), static: true,
                thisName: interfaceProperty.name, initThisFunc: interfaceProperty.initMethod, to: writer)
        }
    }

    fileprivate func writeDefaultInitializer(_ classDefinition: ClassDefinition, to writer: SwiftTypeDefinitionWriter) throws {
        writer.output.writeLine("// IActivationFactory")

        // 00000035-0000-0000-C000-000000000046
        let iactivationFactoryID = UUID(uuid: (
            0x00, 0x00, 0x00, 0x35,
            0x00, 0x00,
            0x00, 0x00,
            0xC0, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x46))
        let interfaceProperty = try writeSecondaryInterfaceProperty(
            interfaceName: "IActivationFactory", abiName: "IActivationFactory", iid: iactivationFactoryID,
            staticOf: classDefinition, to: writer)

        // let defaultInterface = DefaultAttribute.getDefaultInterface(classDefinition)!
        // let defaultInterfaceProjection = try projection.getTypeProjection(defaultInterface.asNode)

        writer.writeInit(visibility: .public, override: false, throws: true) { writer in
            writer.writeStatement("try Self.\(interfaceProperty.initMethod)()")
            writer.writeStatement("var inspectable: UnsafeMutablePointer<\(projection.abiModuleName).IInspectable>? = nil")
            writer.writeStatement("defer { IUnknownPointer.release(inspectable) }")
            writer.writeStatement("try HResult.throwIfFailed(Self.\(interfaceProperty.name).pointee.lpVtbl.pointee.ActivateInstance("
                + "Self.\(interfaceProperty.name), &inspectable))")
            //writer.writeStatement("var instance: UnsafeMutablePointer<\(defaultInterfaceProjection)>? = nil")
        }
    }
}