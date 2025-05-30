import CodeWriters
import Collections
import DotNetMetadata
import ProjectionModel
import WindowsMetadata

/// Writes a class implementing COMImport/WinRTImport for an interface, delegate or activatable class
internal func writeCOMImportClass(
        _ type: BoundType,
        visibility: SwiftVisibility,
        name: String,
        bindingType: SwiftType,
        projection: Projection,
        to writer: SwiftTypeDefinitionWriter) throws {
    let importBaseType: SwiftType
    let protocolConformances: [SwiftType]
    switch type.definition {
        case let interfaceDefinition as InterfaceDefinition:
            importBaseType = SupportModules.WinRT.winRTImport(of: bindingType)
            protocolConformances = [.named(try projection.toProtocolName(interfaceDefinition)) ]
        case is DelegateDefinition:
            importBaseType =  SupportModules.COM.comImport(of: bindingType)
            protocolConformances = []
        default: fatalError()
    }

    // private final class Import: WinRTImport<IFooBinding>, IFooProtocol {}
    try writer.writeClass(
        visibility: visibility, final: true, name: name,
        base: importBaseType,
        protocolConformances: protocolConformances) { writer throws in

        let interfaces = try type.definition.baseInterfaces.map {
            try $0.interface.bindGenericParams(typeArgs: type.genericArgs)
        }
        try writeGenericTypeAliases(interfaces: interfaces, projection: projection, to: writer)

        // Primary interface implementation
        try writeMemberDefinitions(
            abiType: type, documentation: false, thisPointer: .init(name: "_interop"),
            projection: projection, to: writer)

        // Secondary interface implementations
        if let interfaceDefinition = type.definition as? InterfaceDefinition {
            // Midlrt.exe generates WinMD files where the list of base interfaces are already a transitive closure.
            // For example, Windows.Foundation.Diagnostics.ILoggingActivity2 declares ILoggingActivity and IClosable as bases,
            // even though IClosable would come transitively from ILoggingActivity.
            // But Windows.Foundation.Collections.IObservableVector<T> and IObservableMap<Key, Value> do not honor this;
            // they only declare their direct IVector/IMap bases and not IIterable.
            // This is presumably an error in their authoring since they are not defined in idl.
            var secondaryInterfaces: [BoundInterface] = []
            try gatherTransitiveBaseInterfaces(
                of: BoundInterface(interfaceDefinition, genericArgs: type.genericArgs),
                into: &secondaryInterfaces)

            for secondaryInterface in secondaryInterfaces {
                let secondaryInterfaceName = try WinRTTypeName.from(type: secondaryInterface.asBoundType).description
                writer.writeMarkComment("\(secondaryInterfaceName) members")
                try writeMemberDefinitions(
                    abiType: secondaryInterface.asBoundType, documentation: false,
                    thisPointer: .init(name: SecondaryInterfaces.getPropertyName(secondaryInterface), lazy: true),
                    projection: projection, to: writer)
            }

            if !secondaryInterfaces.isEmpty {
                writer.writeMarkComment("Implementation boilerplate")
            }

            for secondaryInterface in secondaryInterfaces {
                try SecondaryInterfaces.writeDeclaration(secondaryInterface, static: false, projection: projection, to: writer)
            }
        }
    }
}

fileprivate func gatherTransitiveBaseInterfaces(of boundInterface: BoundInterface, into bases: inout [BoundInterface]) throws {
    for baseDeclaration in boundInterface.definition.baseInterfaces {
        let boundBase = try baseDeclaration.interface.bindGenericParams(typeArgs: boundInterface.genericArgs)
        guard !bases.contains(boundBase) else { continue }

        bases.append(boundBase)
        try gatherTransitiveBaseInterfaces(of: boundBase, into: &bases)
    }
}

/// Gathers all generic arguments from the given interfaces and writes them as type aliases
/// For example, if an interface is IMap<String, Int32>, write K = String and V = Int32
internal func writeGenericTypeAliases(interfaces: [BoundInterface], projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    var typeAliases = OrderedDictionary<String, SwiftType>()

    for interface in interfaces {
        for (index, genericArg) in interface.genericArgs.enumerated() {
            let genericParamName = interface.definition.genericParams[index].name
            if typeAliases[genericParamName] == nil {
                typeAliases[genericParamName] = try projection.toTypeExpression(genericArg)
            }
        }
    }

    for (name, type) in typeAliases {
        writer.writeTypeAlias(visibility: .public, name: name, target: type)
    }
}