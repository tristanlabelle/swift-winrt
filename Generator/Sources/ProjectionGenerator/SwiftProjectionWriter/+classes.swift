import CodeWriters
import Collections
import DotNetMetadata
import WindowsMetadata
import struct Foundation.UUID

extension SwiftProjectionWriter {
    internal func writeClassProjection(_ classDefinition: ClassDefinition) throws {
        let typeName = try projection.toTypeName(classDefinition)
        if classDefinition.isAbstract && classDefinition.isSealed {
            // Static class
            assert(classDefinition.baseInterfaces.isEmpty)
            try sourceFileWriter.writeEnum(
                visibility: SwiftProjection.toVisibility(classDefinition.visibility),
                name: typeName) { try writeClassBody(classDefinition, to: $0) }
        }
        else {
            var protocolConformances: [SwiftType] = [.identifier("WinRTProjection")]
            for baseInterface in classDefinition.baseInterfaces {
                let interfaceDefinition = try baseInterface.interface.definition
                guard interfaceDefinition.isPublic else { continue }
                protocolConformances.append(.identifier(try projection.toProtocolName(interfaceDefinition)))
            }

            try sourceFileWriter.writeClass(
                visibility: SwiftProjection.toVisibility(classDefinition.visibility), final: true, name: typeName,
                base: .identifier(name: "WinRTImport", genericArgs: [.identifier(name: typeName)]),
                protocolConformances: protocolConformances) { try writeClassBody(classDefinition, to: $0) }
        }
    }

    fileprivate func writeClassBody(_ classDefinition: ClassDefinition, to writer: SwiftTypeDefinitionWriter) throws {
        if let defaultInterface = try DefaultAttribute.getDefaultInterface(classDefinition) {
            try writeWinRTProjectionConformance(
                interfaceOrDelegate: defaultInterface.asBoundType, classDefinition: classDefinition, to: writer)
        }

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

        // As soon as we declare one initializer, we must redeclare required initializers
        writer.writeInit(visibility: .public, required: true,
                params: [.init(label: "transferringRef", name: "comPointer", type: .identifier("COMPointer"))]) { writer in
            writer.writeStatement("super.init(transferringRef: comPointer)")
        }

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
                        try writeProjectionMethodBody(
                            thisPointer: .getter(interfaceProperty.getter, static: true),
                            params: paramProjections,
                            returnParam: returnProjection,
                            abiName: method.name,
                            isInitializer: true,
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

        writer.writeInit(visibility: .public, convenience: true, throws: true) { writer in
            writer.writeStatement("let _factory = try Self.\(interfaceProperty.getter)()")
            writer.writeStatement("var inspectable: UnsafeMutablePointer<\(projection.abiModuleName).\(CAbi.iinspectableName)>? = nil")
            writer.writeStatement("defer { IUnknownPointer.release(inspectable) }")
            writer.writeStatement("try WinRTError.throwIfFailed(_factory.pointee.lpVtbl.pointee.ActivateInstance(_factory, &inspectable))")
            writer.writeStatement("guard let inspectable else { throw COM.HResult.Error.noInterface }")
            writer.writeBlankLine()
            writer.writeStatement("var iid = COM.GUIDProjection.toABI(Self.id)")
            writer.writeStatement("var instance: UnsafeMutableRawPointer? = nil")
            writer.writeStatement("try HResult.throwIfFailed(inspectable.pointee.lpVtbl.pointee.QueryInterface(inspectable, &iid, &instance))")
            writer.writeStatement("guard let instance else { throw COM.HResult.Error.noInterface }")
            writer.writeBlankLine()
            writer.writeStatement("self.init(transferringRef: instance.bindMemory(to: COMInterface.self, capacity: 1))")
        }
    }
}