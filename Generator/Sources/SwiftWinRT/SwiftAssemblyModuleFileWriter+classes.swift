import CodeWriters
import Collections
import DotNetMetadata
import WindowsMetadata

extension SwiftAssemblyModuleFileWriter {
    internal func writeClass(_ classDefinition: ClassDefinition) throws {
        try sourceFileWriter.writeClass(
                visibility: SwiftProjection.toVisibility(classDefinition.visibility, inheritableClass: !classDefinition.isSealed),
                final: classDefinition.isSealed,
                name: projection.toTypeName(classDefinition),
                typeParameters: classDefinition.genericParams.map { $0.name },
                base: projection.toBaseType(classDefinition.base),
                protocolConformances: classDefinition.baseInterfaces.compactMap { try projection.toBaseType($0.interface.asType) }) { writer throws in
            try writeTypeAliasesForBaseGenericArgs(of: classDefinition, to: writer)
            try writeClassMembers(classDefinition, to: writer)
        }
    }

    fileprivate func writeTypeAliasesForBaseGenericArgs(of typeDefinition: TypeDefinition, to writer: SwiftRecordBodyWriter) throws {
        var baseTypes = try typeDefinition.baseInterfaces.map { try $0.interface.asType }
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

    fileprivate func writeClassMembers(_ classDefinition: ClassDefinition, to writer: SwiftRecordBodyWriter) throws {
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
        let isStatic = classDefinition.isAbstract && classDefinition.isSealed
        assert(isStatic == classDefinition.baseInterfaces.isEmpty)
        let protocolConformances: [SwiftType] = try isStatic ? [] : [.identifier("WinRTProjection")]
            + classDefinition.baseInterfaces.map { .identifier(try projection.toProtocolName($0.interface.definition)) }
        try sourceFileWriter.writeClass(
                visibility: SwiftProjection.toVisibility(classDefinition.visibility), final: true, name: typeName,
                base: isStatic ? nil : .identifier(name: "WinRTProjectionBase", genericArgs: [.identifier(name: typeName)]),
                protocolConformances: protocolConformances) { writer throws in

            if isStatic {
                writer.writeInit(visibility: .private) { writer in }
            }
            else {
                let defaultInterface = try DefaultAttribute.getDefaultInterface(classDefinition)!
                try writeWinRTProjectionConformance(type: classDefinition.bindType(), interface: defaultInterface, to: writer)
            }

            try writeGenericTypeAliases(interfaces: classDefinition.baseInterfaces.map { try $0.interface }, to: writer)

            try writeInterfaceImplementations(classDefinition.bindType(), to: writer)

            for staticAttribute in try classDefinition.getAttributes(StaticAttribute.self) {
                _ = try writeNonDefaultInterfaceImplementation(
                    staticAttribute.interface.bind(), staticOf: classDefinition, to: writer)
            }
        }
    }
}