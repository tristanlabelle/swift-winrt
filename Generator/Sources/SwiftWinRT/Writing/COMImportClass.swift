import CodeWriters
import Collections
import DotNetMetadata
import ProjectionGenerator
import WindowsMetadata

/// Writes a class implementing COMImport/WinRTImport for an interface, delegate or activatable class
internal func writeCOMImportClass(
        _ type: BoundType,
        visibility: SwiftVisibility,
        name: String,
        projectionName: String,
        projection: SwiftProjection,
        to writer: SwiftTypeDefinitionWriter) throws {
    let importBaseTypeName: String
    let protocolConformances: [SwiftType]
    switch type.definition {
        case let interfaceDefinition as InterfaceDefinition:
            importBaseTypeName = "WinRTImport"
            protocolConformances = [ .identifier(name: try projection.toProtocolName(interfaceDefinition)) ]
        case is DelegateDefinition:
            importBaseTypeName = "COMImport"
            protocolConformances = []
        default: fatalError()
    }

    // private final class Import: WinRTImport<IFooProjection>, IFooProtocol {}
    try writer.writeClass(
        visibility: visibility, final: true, name: name,
        base: .identifier(name: importBaseTypeName, genericArgs: [.identifier(name: projectionName)]),
        protocolConformances: protocolConformances) { writer throws in

        let interfaces = try type.definition.baseInterfaces.map {
            try $0.interface.bindGenericParams(typeArgs: type.genericArgs)
        }
        try writeGenericTypeAliases(interfaces: interfaces, projection: projection, to: writer)

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
        try writeInterfaceImplementation(
            interfaceOrDelegate: type, thisPointer: .init(name: "_interop"),
            projection: projection, to: writer)

        // Secondary interface implementations
        if type.definition is InterfaceDefinition {
            var propertiesToRelease = [String]()
            for baseInterface in type.definition.baseInterfaces {
                let secondaryInterface = try baseInterface.interface.bindGenericParams(typeArgs: type.genericArgs)
                try writer.writeCommentLine(WinRTTypeName.from(type: secondaryInterface.asBoundType).description)
                let declaration = try writeSecondaryInterfaceDeclaration(secondaryInterface, projection: projection, to: writer)
                try writeInterfaceImplementation(
                    interfaceOrDelegate: secondaryInterface.asBoundType, thisPointer: declaration.thisPointer,
                    projection: projection, to: writer)
                propertiesToRelease.append(declaration.storedPropertyName)
            }

            if !propertiesToRelease.isEmpty {
                writer.writeDeinit { writer in
                    for storedProperty in propertiesToRelease {
                        writer.writeStatement("\(storedProperty)?.release()")
                    }
                }
            }
        }
    }
}

/// Gathers all generic arguments from the given interfaces and writes them as type aliases
/// For example, if an interface is IMap<String, Int32>, write K = String and V = Int32
internal func writeGenericTypeAliases(interfaces: [BoundInterface], projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    var typeAliases = OrderedDictionary<String, SwiftType>()

    for interface in interfaces {
        for (index, genericArg) in interface.genericArgs.enumerated() {
            let genericParamName = interface.definition.genericParams[index].name
            if typeAliases[genericParamName] == nil {
                typeAliases[genericParamName] = try projection.toType(genericArg)
            }
        }
    }

    for (name, type) in typeAliases {
        writer.writeTypeAlias(visibility: .public, name: name, target: type)
    }
}