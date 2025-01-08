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
        if swiftBug72724 == nil { writer.output.writeFullLine("#if compiler(>=6.1)", groupWithNext: true) }
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
        baseProtocols.append(.named(try projection.toProtocolName(baseInterface.definition)))
        for (i, genericArg) in baseInterface.genericArgs.enumerated() {
            let genericParam = baseInterface.definition.genericParams[i]
            // Ignore generic arguments that are the same as the current interface's generic arguments,
            // For example, IVector<T> : IIterable<T>, so we don't generate "where T == T"
            if case .genericParam(let genericParamArg) = genericArg,
                genericParamArg.name == genericParam.name { continue }
            whereGenericConstraints[genericParam.name] = try projection.toTypeExpression(genericArg)
        }
    }

    if baseProtocols.isEmpty { baseProtocols.append(.named("IInspectableProtocol")) }

    let protocolName = try projection.toProtocolName(interfaceDefinition)
    try writer.writeProtocol(
            documentation: projection.getDocumentationComment(interfaceDefinition),
            attributes: projection.getAttributes(interfaceDefinition),
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
                attributes: projection.getAttributes(method),
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
                    attributes: projection.getAttributes(addAccessor, deprecator: event) + [ .discardableResult ],
                    name: Projection.toMemberName(event),
                    params: addAccessor.params.map { try projection.toParameter(label: "adding", $0) },
                    throws: true,
                    returnType: SupportModules.WinRT.eventRegistration)
            }

            if let removeAccessor = try event.removeAccessor {
                try writer.writeFunc(
                    attributes: projection.getAttributes(removeAccessor, deprecator: event),
                    name: Projection.toMemberName(event),
                    params: removeAccessor.params.map { try projection.toParameter(label: "removing", $0) },
                    throws: true)
            }
        }

        // Write properties as "var foo: T { get throws}" and "func setFoo(_ newValue: T) throws",
        // to provide a way to handle errors (Swift does not support throwing settable properties)
        // We'll generate non-throwing "var foo_: T! { get set }" as an extension.
        for property in interfaceDefinition.properties {
            if let getter = try property.getter {
                try writer.writeProperty(
                    documentation: projection.getDocumentationComment(property, accessor: .getter),
                    attributes: projection.getAttributes(getter, deprecator: property),
                    name: Projection.toMemberName(property),
                    type: projection.toReturnType(getter.returnType),
                    throws: true)
            }

            if let setter = try property.setter {
                try writer.writeFunc(
                    groupAsProperty: true,
                    documentation: projection.getDocumentationComment(property, accessor: .setter),
                    attributes: projection.getAttributes(setter, deprecator: property),
                    name: Projection.toMemberName(property),
                    params: setter.params.map { try projection.toParameter($0) },
                    throws: true)
            }
        }
    }

    // Write non-throwing properties as an extension
    try writeNonthrowingPropertiesExtension(interfaceDefinition, projection: projection, to: writer)
}

fileprivate func writeProtocolTypeAlias(_ interfaceDefinition: InterfaceDefinition, projection: Projection, to writer: SwiftSourceFileWriter) throws {
    try writer.writeTypeAlias(
        documentation: projection.getDocumentationComment(interfaceDefinition),
        attributes: [ projection.getAvailableAttribute(interfaceDefinition) ].compactMap { $0 },
        visibility: Projection.toVisibility(interfaceDefinition.visibility),
        name: projection.toTypeName(interfaceDefinition),
        typeParams: interfaceDefinition.genericParams.map { $0.name },
        target: .named(
            projection.toProtocolName(interfaceDefinition),
            genericArgs: interfaceDefinition.genericParams.map {.named($0.name) }).existential())
}

fileprivate func writeNonthrowingPropertiesExtension(
        _ interfaceDefinition: InterfaceDefinition, projection: Projection, to writer: SwiftSourceFileWriter) throws {
    // Only write the extension if we have at least one property having both a getter and setter
    let getSetProperties = try interfaceDefinition.properties.filter { try $0.getter != nil }
    guard !getSetProperties.isEmpty else { return }

    let protocolType = SwiftType.named(try projection.toProtocolName(interfaceDefinition))
    try writer.writeExtension(
            attributes: [ projection.getAvailableAttribute(interfaceDefinition) ].compactMap { $0 },
            type: protocolType) { writer in
        for property in getSetProperties {
            try writeNonthrowingPropertyImplementation(
                property: property, static: false, projection: projection, to: writer)
        }
    }
}