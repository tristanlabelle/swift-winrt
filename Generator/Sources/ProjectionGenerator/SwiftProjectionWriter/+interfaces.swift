import CodeWriters
import Collections
import DotNetMetadata
import DotNetXMLDocs
import WindowsMetadata

extension SwiftProjectionWriter {
    // Interfaces are generated as two types: a protocol and an existential typealias.
    // Given an interface IFoo, we generate:
    //
    //     protocol IFooProtocol { ... }
    //     typealias IFoo = any IFooProtocol
    //
    // This provides a more natural (C#-like) syntax when using those types:
    //
    //     var foo: IFoo? = getFoo()
    internal func writeInterfaceDefinition(_ interface: InterfaceDefinition, to writer: SwiftSourceFileWriter) throws {
        try writeProtocol(interface, to: writer)
        try writeProtocolTypeAlias(interface, to: writer)

        let typeName = try projection.toProtocolName(interface)
        switch interface.name {
            case "IAsyncAction", "IAsyncActionWithProgress`1":
                try writeIAsyncExtensions(protocolName: typeName, resultType: nil, to: writer)
            case "IAsyncOperation`1", "IAsyncOperationWithProgress`2":
                try writeIAsyncExtensions(
                    protocolName: typeName,
                    resultType: .identifier(name: String(interface.genericParams[0].name)),
                    to: writer)
            default: break
        }
    }

    internal func writeDelegateDefinition(_ delegateDefinition: DelegateDefinition, to writer: SwiftSourceFileWriter) throws {
        try writer.writeTypeAlias(
            documentation: projection.getDocumentationComment(delegateDefinition),
            visibility: SwiftProjection.toVisibility(delegateDefinition.visibility),
            name: try projection.toTypeName(delegateDefinition),
            typeParams: delegateDefinition.genericParams.map { $0.name },
            target: .function(
                params: delegateDefinition.invokeMethod.params.map { try projection.toType($0.type) },
                throws: true,
                returnType: delegateDefinition.invokeMethod.hasReturnValue 
                    ? projection.toReturnType(delegateDefinition.invokeMethod.returnType)
                    : .void
            )
        )
    }

    fileprivate func writeProtocol(_ interfaceDefinition: InterfaceDefinition, to writer: SwiftSourceFileWriter) throws {
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
        try writer.writeProtocol(
            documentation: documentation.map { projection.toDocumentationComment($0) },
            visibility: SwiftProjection.toVisibility(interfaceDefinition.visibility),
            name: projection.toProtocolName(interfaceDefinition),
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

            for property in interfaceDefinition.properties {
                if try property.getter != nil {
                    try writer.writeProperty(
                        documentation: projection.getDocumentationComment(property),
                        name: projection.toMemberName(property),
                        type: projection.toReturnType(property.type),
                        throws: true,
                        set: false)
                }

                if let setter = try property.setter {
                    try writer.writeFunc(
                        isPropertySetter: true,
                        name: projection.toMemberName(property),
                        params: setter.params.map { try projection.toParameter($0) },
                        throws: true)
                }
            }

            for event in interfaceDefinition.events {
                if let addAccessor = try event.addAccessor {
                    try writer.writeFunc(
                        documentation: projection.getDocumentationComment(event),
                        name: projection.toMemberName(event),
                        params: addAccessor.params.map { try projection.toParameter(label: "adding", $0) },
                        throws: true,
                        returnType: .chain("WindowsRuntime", "EventRegistration"))
                }

                if let removeAccessor = try event.removeAccessor {
                    try writer.writeFunc(
                        name: projection.toMemberName(event),
                        params: removeAccessor.params.map { try projection.toParameter(label: "removing", $0) },
                        throws: true)
                }
            }

            for method in interfaceDefinition.methods.filter({ $0.visibility == .public }) {
                guard method.nameKind == .regular else { continue }
                try writer.writeFunc(
                    documentation: projection.getDocumentationComment(method),
                    name: projection.toMemberName(method),
                    typeParams: method.genericParams.map { $0.name },
                    params: method.params.map { try projection.toParameter($0) },
                    throws: true,
                    returnType: method.hasReturnValue ? projection.toReturnType(method.returnType) : nil)
            }
        }
    }

    fileprivate func writeProtocolTypeAlias(_ interfaceDefinition: InterfaceDefinition, to writer: SwiftSourceFileWriter) throws {
        writer.writeTypeAlias(
            documentation: projection.getDocumentationComment(interfaceDefinition),
            visibility: SwiftProjection.toVisibility(interfaceDefinition.visibility),
            name: try projection.toTypeName(interfaceDefinition),
            typeParams: interfaceDefinition.genericParams.map { $0.name },
            target: .identifier(
                protocolModifier: .existential,
                name: try projection.toProtocolName(interfaceDefinition),
                genericArgs: interfaceDefinition.genericParams.map { .identifier(name: $0.name) }))
    }

    internal func writeInterfaceOrDelegateProjection(_ typeDefinition: TypeDefinition, genericArgs: [TypeNode]?, to writer: SwiftSourceFileWriter) throws {
        if typeDefinition.genericArity == 0 {
            // Non-generic type, create a standard projection type.
            // enum IVectorProjection: WinRTProjection... {}
            try writeInterfaceOrDelegateProjection(typeDefinition.bindType(),
                projectionName: try projection.toProjectionTypeName(typeDefinition),
                to: writer)
        }
        else if let genericArgs {
            // Generic type specialization. Create a projection for the specialization.
            // extension IVectorProjection {
            //     internal final class Boolean: WinRTProjection... {}
            // }
            try writer.writeExtension(
                    name: projection.toProjectionTypeName(typeDefinition)) { writer in
                try writeInterfaceOrDelegateProjection(
                    typeDefinition.bindType(genericArgs: genericArgs),
                    projectionName: try SwiftProjection.toProjectionInstanciationTypeName(genericArgs: genericArgs),
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

            try writeCOMProjectionConformance(
                apiType: type, abiType: type,
                toSwiftBody: { writer, paramName in
                    // Let COMImport attempt unwrapping first
                    writer.writeStatement("toSwift(transferringRef: \(paramName), importType: Import.self)")
                },
                toCOMBody: { writer, paramName in
                    if type.definition is InterfaceDefinition {
                        // Interfaces might be SwiftObjects or previous COMImports
                        writer.writeStatement("try toCOM(\(paramName), importType: Import.self)")
                    }
                    else {
                        // Delegates have no identity, so create one for them
                        writer.writeReturnStatement(value: "COMWrappingExport<Self>(implementation: \(paramName)).toCOM()")
                    }
                },
                to: writer)

            // private final class Import: WinRTImport<IFooProjection>, IFooProtocol {}
            try writer.writeClass(
                visibility: .private, final: true, name: "Import",
                base: .identifier(name: importBaseTypeName, genericArgs: [.identifier(name: projectionName)]),
                protocolConformances: protocolConformances) { writer throws in

                let interfaces = try type.definition.baseInterfaces.map {
                    try $0.interface.bindGenericParams(typeArgs: type.genericArgs)
                }
                try writeGenericTypeAliases(interfaces: interfaces, to: writer)

                if type.definition is DelegateDefinition {
                    // public override var swiftObject: SwiftObject { self.invoke }
                    writer.writeComputedProperty(
                            visibility: .public, override: true, name: "swiftObject",
                            type: .identifier("SwiftObject")) { writer in
                        writer.writeStatement("self.invoke")
                    }
                }

                // Primary interface implementation
                try writer.writeCommentLine(WinRTTypeName.from(type: type).description)
                try writeInterfaceImplementation(interfaceOrDelegate: type, thisPointer: .name("comPointer"), to: writer)

                // Secondary interface implementations
                if type.definition is InterfaceDefinition {
                    var propertiesToRelease = [String]()
                    for secondaryInterface in try getAllBaseInterfaces(type) {
                        try writer.writeCommentLine(WinRTTypeName.from(type: secondaryInterface.asBoundType).description)
                        let property = try writeSecondaryInterfaceProperty(secondaryInterface, to: writer)
                        try writeInterfaceImplementation(
                            interfaceOrDelegate: secondaryInterface.asBoundType,
                            thisPointer: .getter(property.getter, static: false),
                            to: writer)
                        propertiesToRelease.append(property.name)
                    }

                    if !propertiesToRelease.isEmpty {
                        writer.writeDeinit { writer in
                            for storedProperty in propertiesToRelease {
                                writer.writeStatement("if let \(storedProperty) { IUnknownPointer.release(\(storedProperty)) }")
                            }
                        }
                    }
                }
            }

            // public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &virtualTable) { $0 } }
            // private static var virtualTable = COMVirtualTable(...)
            writer.writeComputedProperty(
                    visibility: .public, static: true, name: "virtualTablePointer",
                    type: .identifier("COMVirtualTablePointer")) { writer in
                writer.writeStatement("withUnsafePointer(to: &virtualTable) { $0 }")
            }

            try writer.writeStoredProperty(
                visibility: .private, static: true, declarator: .var, name: "virtualTable",
                initializer: { try writeVirtualTable(interfaceOrDelegate: type, to: $0) })
        }
    }

    fileprivate func writeIAsyncExtensions(protocolName: String, resultType: SwiftType?, to writer: SwiftSourceFileWriter) throws {
        writer.writeExtension(name: protocolName) { writer in
            // public get() async throws
            writer.writeFunc(visibility: .public, name: "get", async: true, throws: true, returnType: resultType) { writer in
                writer.output.writeIndentedBlock(header: "if try status == .started {", footer: "}") {
                    // We can't await if the completed handler is already set
                    writer.writeStatement("guard try COM.NullResult.catch(completed) == nil else { throw COM.HResult.Error.illegalMethodCall }")
                    writer.writeStatement("let awaiter = WindowsRuntime.AsyncAwaiter()")
                    writer.writeStatement("try completed({ _, _ in _Concurrency.Task { await awaiter.signal() } })")
                    writer.writeStatement("await awaiter.wait()")
                }

                // Handles exceptions and cancelation
                writer.writeStatement("return try getResults()")
            }
        }
    }
}