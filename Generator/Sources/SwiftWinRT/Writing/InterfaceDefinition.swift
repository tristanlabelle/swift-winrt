import CodeWriters
import Collections
import DotNetMetadata
import DotNetXMLDocs
import ProjectionModel
import WindowsMetadata

// Interfaces are generated as two types: a protocol and an existential typealias.
// Given an interface IFoo, we generate:
//
//     typealias IFoo = any IFooProtocol
//     protocol IFooProtocol { ... }
//
// This provides a more natural (C#-like) syntax when using those types:
//
//     var foo: IFoo? = getFoo()
internal func writeInterfaceDefinition(_ interface: InterfaceDefinition, projection: SwiftProjection, to writer: SwiftSourceFileWriter) throws {
    if SupportModules.WinRT.getBuiltInTypeKind(interface) != nil {
        // Defined in WindowsRuntime, merely reexport it here.
        let protocolName = try projection.toProtocolName(interface)
        writer.writeImport(exported: true, kind: .protocol, module: SupportModules.WinRT.moduleName, symbolName: protocolName)

        // Import the existential typealias as a protocol to work around compiler bug https://github.com/apple/swift/issues/72724:
        // "'IFoo' was imported as 'typealias', but is a protocol"
        let typeName = try projection.toTypeName(interface)
        writer.writeImport(exported: true, kind: .protocol, module: SupportModules.WinRT.moduleName, symbolName: typeName)
    }
    else {
        try writeProtocolTypeAlias(interface, projection: projection, to: writer)
        try writeProtocol(interface, projection: projection, to: writer)
        try writeInterfaceExtensions(interface, projection: projection, to: writer)
    }
}

fileprivate func writeProtocol(_ interfaceDefinition: InterfaceDefinition, projection: SwiftProjection, to writer: SwiftSourceFileWriter) throws {
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

    let documentation = projection.getDocumentation(interfaceDefinition)
    let protocolName = try projection.toProtocolName(interfaceDefinition)
    try writer.writeProtocol(
            documentation: documentation.map { projection.toDocumentationComment($0) },
            visibility: SwiftProjection.toVisibility(interfaceDefinition.visibility),
            name: protocolName,
            typeParams: interfaceDefinition.genericParams.map { $0.name },
            bases: baseProtocols,
            whereClauses: whereGenericConstraints.map { "\($0.key) == \($0.value)" }) { writer throws in
        for genericParam in interfaceDefinition.genericParams {
            writer.writeAssociatedType(
                documentation: documentation?.typeParams
                    .first { $0.name == genericParam.name }
                    .flatMap { $0.description }
                    .map { projection.toDocumentationComment($0) },
                name: genericParam.name)
        }

        for method in interfaceDefinition.methods.filter({ $0.visibility == .public }) {
            guard method.nameKind == .regular else { continue }
            try writer.writeFunc(
                documentation: projection.getDocumentationComment(method),
                name: SwiftProjection.toMemberName(method),
                typeParams: method.genericParams.map { $0.name },
                params: method.params.map { try projection.toParameter($0) },
                throws: true,
                returnType: method.hasReturnValue ? projection.toReturnType(method.returnType) : nil)
        }

        for event in interfaceDefinition.events {
            if let addAccessor = try event.addAccessor {
                try writer.writeFunc(
                    documentation: projection.getDocumentationComment(event),
                    name: SwiftProjection.toMemberName(event),
                    params: addAccessor.params.map { try projection.toParameter(label: "adding", $0) },
                    throws: true,
                    returnType: SupportModules.WinRT.eventRegistration)
            }

            if let removeAccessor = try event.removeAccessor {
                try writer.writeFunc(
                    name: SwiftProjection.toMemberName(event),
                    params: removeAccessor.params.map { try projection.toParameter(label: "removing", $0) },
                    throws: true)
            }
        }

        // Write properties as "_getFoo() throws -> T" and "_setFoo(newValue: T) throws",
        // to provide a way to handle errors.
        // We'll generate non-throwing "var foo: T { get set }" as an extension.
        for property in interfaceDefinition.properties {
            if let getter = try property.getter {
                try writer.writeFunc(
                    documentation: projection.getDocumentationComment(property),
                    name: SwiftProjection.toMemberName(getter),
                    throws: true,
                    returnType: projection.toReturnType(property.type))
            }

            if let setter = try property.setter {
                try writer.writeFunc(
                    isPropertySetter: true,
                    name: SwiftProjection.toMemberName(setter),
                    params: setter.params.map { try projection.toParameter($0) },
                    throws: true)
            }
        }
    }

    // Write fatalError'ing properties as an extension
    try writeExtensionProperties(
        typeDefinition: interfaceDefinition, interfaces: [interfaceDefinition], static: false,
        projection: projection, to: writer)
}

fileprivate func writeProtocolTypeAlias(_ interfaceDefinition: InterfaceDefinition, projection: SwiftProjection, to writer: SwiftSourceFileWriter) throws {
    writer.writeTypeAlias(
        documentation: projection.getDocumentationComment(interfaceDefinition),
        visibility: SwiftProjection.toVisibility(interfaceDefinition.visibility),
        name: try projection.toTypeName(interfaceDefinition),
        typeParams: interfaceDefinition.genericParams.map { $0.name },
        target: .identifier(
            protocolModifier: .any,
            name: try projection.toProtocolName(interfaceDefinition),
            genericArgs: interfaceDefinition.genericParams.map { .identifier(name: $0.name) }))
}
