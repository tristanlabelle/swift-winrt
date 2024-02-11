import CodeWriters
import Collections
import DotNetMetadata
import ProjectionGenerator
import WindowsMetadata
import struct Foundation.UUID

internal func writeClassDefinition(_ classDefinition: ClassDefinition, projection: SwiftProjection, to writer: SwiftSourceFileWriter) throws {
    if let defaultInterface = try DefaultAttribute.getDefaultInterface(classDefinition) {
        try writeClassDefinition(classDefinition, defaultInterface: defaultInterface, projection: projection, to: writer)
    }
    else {
        assert(classDefinition.isStatic)
        assert(classDefinition.baseInterfaces.isEmpty)

        try writer.writeEnum(
                visibility: SwiftProjection.toVisibility(classDefinition.visibility),
                name: try projection.toTypeName(classDefinition)) { writer in
            try writeStaticMembers(classDefinition, projection: projection, to: writer)
        }
    }
}

fileprivate func writeClassDefinition(
        _ classDefinition: ClassDefinition, defaultInterface: BoundInterface, projection: SwiftProjection, to writer: SwiftSourceFileWriter) throws {
    assert(!classDefinition.isStatic)

    let typeName = try projection.toTypeName(classDefinition)
    let projectionTypeName = try projection.toProjectionTypeName(classDefinition)
    let composable = try classDefinition.hasAttribute(ComposableAttribute.self)
    assert(classDefinition.isSealed || composable)
    assert(!classDefinition.isAbstract || composable)

    // Write the Swift class definition
    let base: SwiftType = .chain(.init("WindowsRuntime"), composable
        ? .init("WinRTComposableClass")
        : .init("WinRTImport", genericArgs: [ .identifier(projectionTypeName) ]))

    var protocolConformances: [SwiftType] = []
    for baseInterface in classDefinition.baseInterfaces {
        let interfaceDefinition = try baseInterface.interface.definition
        guard interfaceDefinition.isPublic else { continue }
        protocolConformances.append(.identifier(try projection.toProtocolName(interfaceDefinition)))
    }

    try writer.writeClass(
            visibility: SwiftProjection.toVisibility(classDefinition.visibility, inheritableClass: !classDefinition.isSealed),
            final: classDefinition.isSealed, name: typeName, base: base, protocolConformances: protocolConformances) { writer in
        try writeClassMembers(classDefinition, defaultInterface: defaultInterface, composable: composable, projection: projection, to: writer)
    }
}

fileprivate func writeClassMembers(
        _ classDefinition: ClassDefinition, defaultInterface: BoundInterface, composable: Bool,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    try writeGenericTypeAliases(interfaces: classDefinition.baseInterfaces.map { try $0.interface }, projection: projection, to: writer)

    // Write initializers
    if composable {
        try writeComposableInitializers(classDefinition, defaultInterface: defaultInterface, projection: projection, to: writer)
    }
    else {
        for activatableAttribute in try classDefinition.getAttributes(ActivatableAttribute.self) {
            assert(!composable)
            if let activationFactory = activatableAttribute.factory {
                try writeActivationFactoryInitializers(classDefinition, activationFactory: activationFactory, projection: projection, to: writer)
            }
            else {
                try writeDefaultActivatableInitializer(classDefinition, projection: projection, to: writer)
            }
        }
    }

    try writeInterfaceImplementations(classDefinition, defaultInterface: defaultInterface, composable: composable, projection: projection, to: writer)

    try writeStaticMembers(classDefinition, projection: projection, to: writer)
}

fileprivate func writeInterfaceImplementations(
        _ classDefinition: ClassDefinition, defaultInterface: BoundInterface, composable: Bool,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    // Non-composable classes inherit from COMImport, which manages the pointer to the default interface
    // WinRTComposableClass doesn't do this, so all interfaces are treated as secondary.
    if !composable {
        // Default interface implementation
        try writer.writeCommentLine(WinRTTypeName.from(type: defaultInterface.asBoundType).description)
        try writeInterfaceImplementation(interfaceOrDelegate: defaultInterface.asBoundType, thisPointer: .name("comPointer"), projection: projection, to: writer)
    }

    // Secondary interface implementations
    var propertiesToRelease = [String]()
    for secondaryInterface in try getAllBaseInterfaces(classDefinition.bindType()) {
        if !composable, secondaryInterface == defaultInterface { continue }

        try writer.writeCommentLine(WinRTTypeName.from(type: secondaryInterface.asBoundType).description)
        let property = try writeSecondaryInterfaceProperty(secondaryInterface, projection: projection, to: writer)
        try writeInterfaceImplementation(
            interfaceOrDelegate: secondaryInterface.asBoundType,
            thisPointer: .getter(property.getter, static: false),
            projection: projection,
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

fileprivate func writeStaticMembers(_ classDefinition: ClassDefinition, projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    // Write static members from static interfaces
    for staticAttribute in try classDefinition.getAttributes(StaticAttribute.self) {
        writer.writeCommentLine(try WinRTTypeName.from(type: staticAttribute.interface.bindType()).description)
        let interfaceProperty = try writeSecondaryInterfaceProperty(
            staticAttribute.interface.bind(), staticOf: classDefinition, projection: projection, to: writer)
        try writeInterfaceImplementation(
            interfaceOrDelegate: staticAttribute.interface.bindType(),
            static: true,
            thisPointer: .getter(interfaceProperty.getter, static: true),
            projection: projection,
            to: writer)
    }
}

fileprivate func writeComposableInitializers(
        _ classDefinition: ClassDefinition, defaultInterface: BoundInterface,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    // TODO: Use signatures from composable factory methods
    let defaultInterfaceABIName = try CAbi.mangleName(type: defaultInterface.asBoundType)
    // public init(transferringRef comPointer: UnsafeMutablePointer<CWinRTComponent.SWRT_IFoo>) {
    //     super.init(_transferringRef: IInspectablePointer.cast(comPointer))
    // }
    let param = SwiftParam(label: "transferringRef", name: "comPointer",
        type: .unsafeMutablePointer(to: .chain(projection.abiModuleName, defaultInterfaceABIName)))
    writer.writeInit(visibility: .public, params: [param]) { writer in
        writer.writeStatement("super.init(_transferringRef: IInspectablePointer.cast(comPointer))")
    }
}

fileprivate func writeActivationFactoryInitializers(
        _ classDefinition: ClassDefinition,
        activationFactory: InterfaceDefinition,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    writer.writeCommentLine(try WinRTTypeName.from(type: activationFactory.bindType()).description)
    let interfaceProperty = try writeSecondaryInterfaceProperty(
        activationFactory.bind(), staticOf: classDefinition, projection: projection, to: writer)
    for method in activationFactory.methods {
        let (paramProjections, returnProjection) = try projection.getParamProjections(method: method, genericTypeArgs: [])
        try writer.writeInit(
                visibility: .public,
                convenience: true,
                params: paramProjections.map { $0.toSwiftParam() },
                throws: true) { writer in
            writer.writeStatement("let this = try Self.\(interfaceProperty.getter)()")
            try writeSwiftToABICall(
                params: paramProjections,
                returnParam: returnProjection,
                abiThisPointer: "this",
                abiMethodName: method.name,
                context: .sealedClassInitializer,
                projection: projection,
                to: writer)
        }
    }
}

fileprivate func writeDefaultActivatableInitializer(
        _ classDefinition: ClassDefinition,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
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
        staticOf: classDefinition, projection: projection, to: writer)

    try writer.writeInit(visibility: .public, convenience: true, throws: true) { writer in
        let projectionClassName = try projection.toProjectionTypeName(classDefinition)
        writer.writeStatement("let factory = try Self.\(interfaceProperty.getter)()")
        writer.writeStatement("let instance = try factory.activateInstance(projection: \(projectionClassName).self)")
        writer.writeStatement("self.init(transferringRef: instance)")
    }
}