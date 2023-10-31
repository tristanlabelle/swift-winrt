import CodeWriters
import Collections
import DotNetMetadata
import WindowsMetadata
import struct Foundation.UUID

extension SwiftAssemblyModuleFileWriter {
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
            let protocolConformances: [SwiftType] = try [.identifier("WinRTProjection")]
                + classDefinition.baseInterfaces.map { .identifier(try projection.toProtocolName($0.interface.definition)) }
            try sourceFileWriter.writeClass(
                visibility: SwiftProjection.toVisibility(classDefinition.visibility), final: true, name: typeName,
                base: .identifier(name: "WinRTProjectionBase", genericArgs: [.identifier(name: typeName)]),
                protocolConformances: protocolConformances) { try writeClassBody(classDefinition, to: $0) }
        }
    }

    fileprivate func writeClassBody(_ classDefinition: ClassDefinition, to writer: SwiftTypeDefinitionWriter) throws {
        if let defaultInterface = try DefaultAttribute.getDefaultInterface(classDefinition) {
            try writeWinRTProjectionConformance(
                interfaceOrDelegate: defaultInterface.asBoundType, classDefinition: classDefinition, to: writer)
        }

        try writeGenericTypeAliases(interfaces: classDefinition.baseInterfaces.map { try $0.interface }, to: writer)

        try writeInterfaceImplementations(classDefinition.bindType(), to: writer)

        // Write initializers from activation factories
        let activatableAttributes = try classDefinition.getAttributes(ActivatableAttribute.self)
        if !activatableAttributes.isEmpty {
            // As soon as we declare one initializer, we must redeclare required initializers
            writer.writeInit(visibility: .public, required: true,
                    parameters: [.init(label: "transferringRef", name: "comPointer", type: .identifier("COMPointer"))]) { writer in
                writer.writeStatement("super.init(transferringRef: comPointer)")
            } 

            for activatableAttribute in activatableAttributes {
                if activatableAttribute.factory == nil {
                    try writeDefaultInitializer(classDefinition, to: writer)
                }
            }
        }

        // Write static members from static interfaces
        for staticAttribute in try classDefinition.getAttributes(StaticAttribute.self) {
            let interfaceProperty = try writeSecondaryInterfaceProperty(
                staticAttribute.interface.bind(), staticOf: classDefinition, to: writer)
            try writeMemberImplementations(
                interfaceOrDelegate: staticAttribute.interface.bindType(), static: true,
                thisPointer: .getter(interfaceProperty.getter), to: writer)
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
            interfaceName: "IActivationFactory", abiName: "IActivationFactory", iid: iactivationFactoryID,
            staticOf: classDefinition, to: writer)

        writer.writeInit(visibility: .public, convenience: true, throws: true) { writer in
            writer.writeStatement("let _factory = try Self.\(interfaceProperty.getter)()")
            writer.writeStatement("var inspectable: UnsafeMutablePointer<\(projection.abiModuleName).IInspectable>? = nil")
            writer.writeStatement("defer { IUnknownPointer.release(inspectable) }")
            writer.writeStatement("try HResult.throwIfFailed(_factory.pointee.lpVtbl.pointee.ActivateInstance(_factory, &inspectable))")
            writer.writeStatement("guard let inspectable else { throw COM.HResult.Error.noInterface }")
            writer.writeBlankLine()
            writer.writeStatement("var iid = Self.iid")
            writer.writeStatement("var instance: UnsafeMutableRawPointer? = nil")
            writer.writeStatement("try HResult.throwIfFailed(inspectable.pointee.lpVtbl.pointee.QueryInterface(inspectable, &iid, &instance))")
            writer.writeStatement("guard let instance else { throw COM.HResult.Error.noInterface }")
            writer.writeBlankLine()
            writer.writeStatement("self.init(transferringRef: instance.bindMemory(to: COMInterface.self, capacity: 1))")
        }
    }
}