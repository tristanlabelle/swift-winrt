import CodeWriters
import Collections
import DotNetMetadata
import WindowsMetadata

extension SwiftAssemblyModuleFileWriter {
    // Interfaces are generated as two types: a protocol and an existential typealias.
    // Given an interface IFoo, we generate:
    //
    //     protocol IFooProtocol { ... }
    //     typealias IFoo = any IFooProtocol
    //
    // This provides a more natural (C#-like) syntax when using those types:
    //
    //     var foo: IFoo? = getFoo()
    internal func writeInterface(_ interface: InterfaceDefinition) throws {
        try writeProtocol(interface)
        try writeProtocolTypeAlias(interface)
    }

    internal func writeDelegate(_ delegateDefinition: DelegateDefinition) throws {
        try sourceFileWriter.writeTypeAlias(
            documentation: projection.getDocumentationComment(delegateDefinition),
            visibility: SwiftProjection.toVisibility(delegateDefinition.visibility),
            name: try projection.toTypeName(delegateDefinition),
            typeParameters: delegateDefinition.genericParams.map { $0.name },
            target: .function(
                params: delegateDefinition.invokeMethod.params.map { try projection.toType($0.type) },
                throws: true,
                returnType: projection.toReturnType(delegateDefinition.invokeMethod.returnType)
            )
        )
    }

    fileprivate func writeProtocol(_ interfaceDefinition: InterfaceDefinition) throws {
        var baseProtocols = [SwiftType]()
        var whereGenericConstraints = OrderedDictionary<String, SwiftType>()
        for baseInterface in interfaceDefinition.baseInterfaces {
            let baseInterface = try baseInterface.interface
            baseProtocols.append(SwiftType.identifier(
                try projection.toProtocolName(baseInterface.definition)))
            for (i, genericArg) in baseInterface.genericArgs.enumerated() {
                let genericParam = baseInterface.definition.genericParams[i]
                // Ignore generic arguments that are the same as the current interface's generic arguments,
                // For example, IVector<T> : IIterable<T>, so we don't generate "where T == T"
                if case .genericParam(let genericParamArg) = genericArg,
                    genericParamArg.name == genericParam.name { continue }
                whereGenericConstraints[genericParam.name] = try projection.toType(genericArg)
            }
        }

        if baseProtocols.isEmpty { baseProtocols.append(SwiftType.identifier("IInspectableProtocol")) }

        try sourceFileWriter.writeProtocol(
            documentation: projection.getDocumentationComment(interfaceDefinition),
            visibility: SwiftProjection.toVisibility(interfaceDefinition.visibility),
            name: projection.toProtocolName(interfaceDefinition),
            typeParameters: interfaceDefinition.genericParams.map { $0.name },
            bases: baseProtocols,
            whereClauses: whereGenericConstraints.map { "\($0.key) == \($0.value)" }) { writer throws in

            for genericParam in interfaceDefinition.genericParams {
                writer.writeAssociatedType(name: genericParam.name)
            }

            for property in interfaceDefinition.properties {
                if let getter = try property.getter, getter.isPublic {
                    try writer.writeProperty(
                        documentation: projection.getDocumentationComment(property),
                        static: property.isStatic,
                        name: projection.toMemberName(property),
                        type: projection.toReturnType(property.type),
                        throws: true,
                        set: false)
                }

                if let setter = try property.setter, setter.isPublic {
                    try writer.writeFunc(
                        isPropertySetter: true,
                        static: property.isStatic,
                        name: projection.toMemberName(property),
                        parameters: [.init(label: "_", name: "newValue", type: projection.toType(property.type))],
                        throws: true)
                }
            }

            for method in interfaceDefinition.methods.filter({ $0.visibility == .public }) {
                guard method.nameKind == .regular else { continue }
                try writer.writeFunc(
                    documentation: projection.getDocumentationComment(method),
                    static: method.isStatic,
                    name: projection.toMemberName(method),
                    typeParameters: method.genericParams.map { $0.name },
                    parameters: method.params.map { try projection.toParameter($0) },
                    throws: true,
                    returnType: projection.toReturnTypeUnlessVoid(method.returnType))
            }
        }
    }

    fileprivate func writeProtocolTypeAlias(_ interfaceDefinition: InterfaceDefinition) throws {
        sourceFileWriter.writeTypeAlias(
            documentation: projection.getDocumentationComment(interfaceDefinition),
            visibility: SwiftProjection.toVisibility(interfaceDefinition.visibility),
            name: try projection.toTypeName(interfaceDefinition),
            typeParameters: interfaceDefinition.genericParams.map { $0.name },
            target: .identifier(
                protocolModifier: .existential,
                name: try projection.toProtocolName(interfaceDefinition),
                genericArgs: interfaceDefinition.genericParams.map { .identifier(name: $0.name) }))
    }

    internal func writeInterfaceOrDelegateProjection(_ typeDefinition: TypeDefinition, genericArgs: [TypeNode]?) throws {
        if typeDefinition.genericArity == 0 {
            // enum IVectorProjection: WinRTProjection... {}
            try writeInterfaceOrDelegateProjection(typeDefinition.bindType(),
                projectionName: try projection.toProjectionTypeName(typeDefinition),
                to: sourceFileWriter)
        }
        else if let genericArgs {
            // extension IVectorProjection {
            //     internal final class Boolean: WinRTProjection... {}
            // }
            try sourceFileWriter.writeExtension(
                    name: projection.toProjectionTypeName(typeDefinition)) { writer in
                try writeInterfaceOrDelegateProjection(
                    typeDefinition.bindType(genericArgs: genericArgs),
                    projectionName: try SwiftProjection.toProjectionInstanciationTypeName(genericArgs: genericArgs),
                    to: writer)
            }
        }
        else {
            // public enum IVectorProjection {}
            try sourceFileWriter.writeEnum(
                visibility: SwiftProjection.toVisibility(typeDefinition.visibility),
                name: projection.toProjectionTypeName(typeDefinition)) { _ in }
        }
    }

    fileprivate func writeInterfaceOrDelegateProjection(_ type: BoundType, projectionName: String, to writer: some SwiftDeclarationWriter) throws {
        let projectionProtocolName: String
        let importBaseTypeName: String
        let protocolConformances: [SwiftType]
        if let interfaceDefinition = type.definition as? InterfaceDefinition {
            projectionProtocolName = "WinRTTwoWayProjection"
            importBaseTypeName = "WinRTImport"
            protocolConformances = [ .identifier(name: try projection.toProtocolName(interfaceDefinition)) ]
        }
        else {
            projectionProtocolName = "COMTwoWayProjection"
            importBaseTypeName = "COMImport"
            protocolConformances = []
        }

        try writer.writeEnum(
                visibility: SwiftProjection.toVisibility(type.definition.visibility),
                name: projectionName,
                protocolConformances: [ .identifier(projectionProtocolName) ]) { writer throws in

            try writeWinRTProjectionConformance(interfaceOrDelegate: type, to: writer)

            try writer.writeClass(
                visibility: .private, final: true, name: "Implementation",
                base: .identifier(name: importBaseTypeName, genericArgs: [.identifier(name: projectionName)]),
                protocolConformances: protocolConformances) { writer throws in

                let interfaces = try type.definition.baseInterfaces.map {
                    try $0.interface.bindGenericParams(typeArgs: type.genericArgs)
                }
                try writeGenericTypeAliases(interfaces: interfaces, to: writer)

                if type.definition is InterfaceDefinition {
                    try writeInterfaceImplementations(type, to: writer)
                }
                else {
                    try writeMemberImplementations(interfaceOrDelegate: type, thisPointer: .name("comPointer"), to: writer)
                }
            }
        }
    }
}