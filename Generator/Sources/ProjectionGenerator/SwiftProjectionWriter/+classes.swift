import CodeWriters
import Collections
import DotNetMetadata
import WindowsMetadata
import struct Foundation.UUID

extension SwiftProjectionWriter {
    internal func writeClass(_ classDefinition: ClassDefinition) throws {
        let typeName = try projection.toTypeName(classDefinition)
        if classDefinition.isStatic {
            assert(classDefinition.baseInterfaces.isEmpty)
            try sourceFileWriter.writeEnum(
                    visibility: SwiftProjection.toVisibility(classDefinition.visibility), name: typeName) {
                try writeClassBody(classDefinition, to: $0)
            }
        }
        else {
            let projectionTypeName = try projection.toProjectionTypeName(classDefinition)
            let base: SwiftType = .chain(
                .init("WindowsRuntime"),
                .init("WinRTImport", genericArgs: [ .identifier(projectionTypeName) ]))

            var protocolConformances: [SwiftType] = []
            for baseInterface in classDefinition.baseInterfaces {
                let interfaceDefinition = try baseInterface.interface.definition
                guard interfaceDefinition.isPublic else { continue }
                protocolConformances.append(.identifier(try projection.toProtocolName(interfaceDefinition)))
            }

            try sourceFileWriter.writeClass(
                    visibility: SwiftProjection.toVisibility(classDefinition.visibility), final: true, name: typeName,
                    base: base, protocolConformances: protocolConformances) {
                try writeClassBody(classDefinition, to: $0)
            }
        }
    }

    fileprivate func writeClassBody(_ classDefinition: ClassDefinition, to writer: SwiftTypeDefinitionWriter) throws {
        try writeGenericTypeAliases(interfaces: classDefinition.baseInterfaces.map { try $0.interface }, to: writer)

        try writeInitializers(classDefinition, to: writer)

        try writeInterfaceImplementations(classDefinition.bindType(), to: writer)

        // Write static members from static interfaces
        for staticAttribute in try classDefinition.getAttributes(StaticAttribute.self) {
            let interfaceProperty = try writeSecondaryInterfaceProperty(
                staticAttribute.interface.bind(), staticOf: classDefinition, to: writer)
            try writeProjectionMembers(
                interfaceOrDelegate: staticAttribute.interface.bindType(),
                static: true,
                thisPointer: .getter(interfaceProperty.getter, static: true),
                to: writer)
        }
    }

    fileprivate func writeInitializers(_ classDefinition: ClassDefinition, to writer: SwiftTypeDefinitionWriter) throws {
        // Write initializers from activation factories
        let activatableAttributes = try classDefinition.getAttributes(ActivatableAttribute.self)
        guard !activatableAttributes.isEmpty else { return }

        for activatableAttribute in activatableAttributes {
            if let activationFactoryInterface = activatableAttribute.factory {
                let interfaceProperty = try writeSecondaryInterfaceProperty(
                    activationFactoryInterface.bind(), staticOf: classDefinition, to: writer)
                for method in activationFactoryInterface.methods {
                    let (paramProjections, returnProjection) = try projection.getParamProjections(method: method, genericTypeArgs: [])
                    try writer.writeInit(
                            visibility: .public,
                            convenience: true,
                            params: paramProjections.map { $0.toSwiftParam() },
                            throws: true) { writer in
                        writer.writeStatement("let _this = try Self.\(interfaceProperty.getter)()")
                        try writeSwiftToABICall(
                            params: paramProjections,
                            returnParam: returnProjection,
                            abiThisPointer: "_this",
                            abiMethodName: method.name,
                            context: .sealedClassInitializer,
                            to: writer)
                    }
                }
            }
            else {
                try writeDefaultInitializer(classDefinition, to: writer)
            }
        }
    }

    fileprivate func writeDefaultInitializer(_ classDefinition: ClassDefinition, to writer: SwiftTypeDefinitionWriter) throws {
        writer.writeCommentLine("IActivationFactory")

        // 00000035-0000-0000-C000-000000000046
        let iactivationFactoryID = UUID(uuid: (
            0x00, 0x00, 0x00, 0x35,
            0x00, 0x00,
            0x00, 0x00,
            0xC0, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x46))
        let interfaceProperty = try writeSecondaryInterfaceProperty(
            interfaceName: "IActivationFactory", abiName: CAbi.iactivationFactoryName, iid: iactivationFactoryID,
            staticOf: classDefinition, to: writer)

        try writer.writeInit(visibility: .public, convenience: true, throws: true) { writer in
            let projectionClassName = try projection.toProjectionTypeName(classDefinition)
            writer.writeStatement("let factory = try Self.\(interfaceProperty.getter)()")
            writer.writeStatement("let instance = try factory.activateInstance(projection: \(projectionClassName).self)")
            writer.writeStatement("self.init(transferringRef: instance)")
        }
    }

    internal func writeClassProjection(_ classDefinition: ClassDefinition) throws {
        if let defaultInterface = try DefaultAttribute.getDefaultInterface(classDefinition) {
            try sourceFileWriter.writeEnum(
                    visibility: SwiftProjection.toVisibility(classDefinition.visibility),
                    name: try projection.toProjectionTypeName(classDefinition),
                    protocolConformances: [ .identifier("WinRTProjection") ]) { writer throws in
                try writeWinRTProjectionConformance(
                    interfaceOrDelegate: defaultInterface.asBoundType, classDefinition: classDefinition, to: writer)
            }
        }
        else {
            assert(classDefinition.isStatic)
        }
    }
}