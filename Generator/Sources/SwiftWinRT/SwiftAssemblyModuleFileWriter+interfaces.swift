import CodeWriters
import Collections
import DotNetMetadata
import WindowsMetadata

extension SwiftAssemblyModuleFileWriter {
    internal func writeInterface(_ interface: InterfaceDefinition) throws {
        try writeProtocol(interface)
        try writeProtocolTypeAlias(interface)
    }

    fileprivate func writeProtocol(_ interface: InterfaceDefinition) throws {
        var baseProtocols = [SwiftType]()
        var whereGenericConstraints = OrderedDictionary<String, SwiftType>()
        for baseInterface in interface.baseInterfaces {
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
            visibility: SwiftProjection.toVisibility(interface.visibility),
            name: projection.toProtocolName(interface),
            typeParameters: interface.genericParams.map { $0.name },
            bases: baseProtocols,
            whereClauses: whereGenericConstraints.map { "\($0.key) == \($0.value)" }) { writer throws in

            for genericParam in interface.genericParams {
                writer.writeAssociatedType(name: genericParam.name)
            }

            for property in interface.properties {
                if let getter = try property.getter, getter.isPublic {
                    try writer.writeProperty(
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

            for method in interface.methods.filter({ $0.visibility == .public }) {
                guard method.nameKind == .regular else { continue }
                try writer.writeFunc(
                    static: method.isStatic,
                    name: projection.toMemberName(method),
                    typeParameters: method.genericParams.map { $0.name },
                    parameters: method.params.map { try projection.toParameter($0) },
                    throws: true,
                    returnType: projection.toReturnTypeUnlessVoid(method.returnType))
            }
        }
    }

    fileprivate func writeProtocolTypeAlias(_ interface: InterfaceDefinition) throws {
        // For every "protocol IFoo", we generate a "typealias AnyIFoo = any IFoo"
        // This enables the shorter "AnyIFoo?" syntax instead of "(any IFoo)?" or "Optional<any IFoo>"
        sourceFileWriter.writeTypeAlias(
            visibility: SwiftProjection.toVisibility(interface.visibility),
            name: try projection.toTypeName(interface),
            typeParameters: interface.genericParams.map { $0.name },
            target: .identifier(
                protocolModifier: .existential,
                name: try projection.toProtocolName(interface),
                genericArgs: interface.genericParams.map { .identifier(name: $0.name) }))
    }

    internal func writeInterfaceProjection(_ interfaceDefinition: InterfaceDefinition, genericArgs: [TypeNode]?) throws {
        if interfaceDefinition.genericArity == 0 {
            // class IVectorProjection: WinRTProjection... {}
            try writeInterfaceProjection(interfaceDefinition.bind(),
                projectionName: try projection.toProjectionTypeName(interfaceDefinition),
                to: sourceFileWriter)
        }
        else if let genericArgs {
            // extension IVectorProjection {
            //     internal final class Boolean: WinRTProjection... {}
            // }
            try sourceFileWriter.writeExtension(
                    name: projection.toProjectionTypeName(interfaceDefinition)) { writer in
                try writeInterfaceProjection(
                    interfaceDefinition.bind(genericArgs: genericArgs),
                    projectionName: try projection.toProjectionInstanciationTypeName(genericArgs: genericArgs),
                    to: writer)
            }
        }
        else {
            // public enum IVectorProjection {}
            try sourceFileWriter.writeEnum(
                visibility: SwiftProjection.toVisibility(interfaceDefinition.visibility),
                name: projection.toProjectionTypeName(interfaceDefinition)) { _ in }
        }
    }

    fileprivate func writeInterfaceProjection(_ interface: BoundInterface, projectionName: String, to writer: some SwiftTypeDeclarationWriter) throws {
        try writer.writeClass(
                visibility: SwiftProjection.toVisibility(interface.definition.visibility),
                final: true, name: projectionName,
                base: .identifier(name: "WinRTProjectionBase", genericArgs: [.identifier(name: projectionName)]),
                protocolConformances: [
                    .identifier("WinRTProjection"), .identifier(name: try projection.toProtocolName(interface.definition))
                ]) { writer throws in

            try writeWinRTProjectionConformance(interfaceOrDelegate: interface.asBoundType, to: writer)

            let interfaces = try interface.definition.baseInterfaces.map {
                try $0.interface.bindGenericParams(typeArgs: interface.genericArgs)
            }
            try writeGenericTypeAliases(interfaces: interfaces, to: writer)

            try writeInterfaceImplementations(interface.asBoundType, to: writer)
        }
    }
}