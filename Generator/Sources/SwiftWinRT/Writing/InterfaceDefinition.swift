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
internal func writeInterfaceDefinition(
        _ interface: InterfaceDefinition,
        projection: Projection,
        swiftBug72724: Bool?,
        to writer: SwiftSourceFileWriter) throws {
    if SupportModules.WinRT.getBuiltInTypeKind(interface) != nil {
        // Defined in WindowsRuntime, merely reexport it here.
        let protocolName = try projection.toProtocolName(interface)
        writer.writeImport(exported: true, kind: .protocol, module: SupportModules.WinRT.moduleName, symbolName: protocolName)

        // Workaround for compiler bug https://github.com/apple/swift/issues/72724.
        // Old versions of the compiler will fail to when using "import typealias" for a typealias of an existential protocol.
        // This will be fixed with the Swift 6.1 compiler, but we can't detect it from the language mode in use.
        // So by default we assume correct behavior iff building for swift >= 6.1, but also allow the user to override it.
        let typeName = try projection.toTypeName(interface)
        if swiftBug72724 == nil { writer.output.writeFullLine("#if swift(>=6.1)", groupWithNext: true) }
        if swiftBug72724 != true { writer.writeImport(exported: true, kind: .typealias, module: SupportModules.WinRT.moduleName, symbolName: typeName) }
        if swiftBug72724 == nil { writer.output.writeFullLine("#else", groupWithNext: true) }
        if swiftBug72724 != false { writer.writeImport(exported: true, kind: .protocol, module: SupportModules.WinRT.moduleName, symbolName: typeName) }
        if swiftBug72724 == nil { writer.output.writeFullLine("#endif") }
    }
    else {
        try writeProtocolTypeAlias(interface, projection: projection, to: writer)
        try writeProtocol(interface, projection: projection, to: writer)
    }
}

fileprivate func writeProtocol(_ interfaceDefinition: InterfaceDefinition, projection: Projection, to writer: SwiftSourceFileWriter) throws {
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

    let protocolName = try projection.toProtocolName(interfaceDefinition)
    try writer.writeProtocol(
            documentation: projection.getDocumentationComment(interfaceDefinition),
            visibility: Projection.toVisibility(interfaceDefinition.visibility),
            name: protocolName,
            typeParams: interfaceDefinition.genericParams.map { $0.name },
            bases: baseProtocols,
            whereClauses: whereGenericConstraints.map { "\($0.key) == \($0.value)" }) { writer throws in
        for genericParam in interfaceDefinition.genericParams {
            writer.writeAssociatedType(
                documentation: projection.getDocumentationComment(genericParam, typeDefinition: interfaceDefinition),
                name: genericParam.name)
        }

        for method in interfaceDefinition.methods.filter({ $0.visibility == .public }) {
            guard method.nameKind == .regular else { continue }
            try writer.writeFunc(
                documentation: projection.getDocumentationComment(method),
                attributes: Projection.getSwiftAttributes(method),
                name: Projection.toMemberName(method),
                typeParams: method.genericParams.map { $0.name },
                params: method.params.map { try projection.toParameter($0) },
                throws: true,
                returnType: method.hasReturnValue ? projection.toReturnType(method.returnType) : nil)
        }

        for event in interfaceDefinition.events {
            if let addAccessor = try event.addAccessor {
                try writer.writeFunc(
                    documentation: projection.getDocumentationComment(event),
                    name: Projection.toMemberName(event),
                    params: addAccessor.params.map { try projection.toParameter(label: "adding", $0) },
                    throws: true,
                    returnType: SupportModules.WinRT.eventRegistration)
            }

            if let removeAccessor = try event.removeAccessor {
                try writer.writeFunc(
                    name: Projection.toMemberName(event),
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
                    documentation: projection.getDocumentationComment(property, accessor: .getter),
                    name: Projection.toMemberName(getter),
                    throws: true,
                    returnType: projection.toReturnType(property.type))
            }

            if let setter = try property.setter {
                try writer.writeFunc(
                    groupAsProperty: true,
                    documentation: projection.getDocumentationComment(property, accessor: .setter),
                    name: Projection.toMemberName(setter),
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

fileprivate func writeProtocolTypeAlias(_ interfaceDefinition: InterfaceDefinition, projection: Projection, to writer: SwiftSourceFileWriter) throws {
    writer.writeTypeAlias(
        documentation: projection.getDocumentationComment(interfaceDefinition),
        visibility: Projection.toVisibility(interfaceDefinition.visibility),
        name: try projection.toTypeName(interfaceDefinition),
        typeParams: interfaceDefinition.genericParams.map { $0.name },
        target: .identifier(
            protocolModifier: .any,
            name: try projection.toProtocolName(interfaceDefinition),
            genericArgs: interfaceDefinition.genericParams.map { .identifier(name: $0.name) }))
}
