import CodeWriters
import Collections
import DotNetMetadata
import ProjectionModel
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
        try writeInterfaceImplementation(
            interfaceOrDelegate: defaultInterface.asBoundType,
            thisPointer: .init(name: "_interop"),
            projection: projection, to: writer)
    }

    let secondaryInterfaces = try classDefinition.baseInterfaces
        .filter { try composable || $0.interface != defaultInterface }
    guard !secondaryInterfaces.isEmpty else { return }

    // Write secondary interface implementations
    for secondaryInterface in secondaryInterfaces {
        let boundType = try secondaryInterface.interface.asBoundType
        try writer.writeCommentLine(WinRTTypeName.from(type: boundType).description)
        try writeInterfaceImplementation(
            interfaceOrDelegate: boundType,
            overridable: secondaryInterface.hasAttribute(OverridableAttribute.self),
            thisPointer: .init(name: SecondaryInterfaces.getPropertyName(secondaryInterface.interface), lazy: true),
            projection: projection, to: writer)
    }

    for secondaryInterface in secondaryInterfaces {
        try SecondaryInterfaces.writeDeclaration(secondaryInterface.interface, projection: projection, to: writer)
    }

    try writer.writeDeinit { writer in
        for secondaryInterface in secondaryInterfaces {
            try SecondaryInterfaces.writeCleanup(secondaryInterface.interface, to: writer)
        }
    }
}

fileprivate func writeStaticMembers(_ classDefinition: ClassDefinition, projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    // Write static members from static interfaces
    for staticAttribute in try classDefinition.getAttributes(StaticAttribute.self) {
        writer.writeCommentLine(try WinRTTypeName.from(type: staticAttribute.interface.bindType()).description)
        try SecondaryInterfaces.writeDeclaration(
            staticAttribute.interface.bind(), staticOf: classDefinition, projection: projection, to: writer)
        try writeInterfaceImplementation(
            interfaceOrDelegate: staticAttribute.interface.bindType(),
            static: true,
            thisPointer: .init(name: SecondaryInterfaces.getPropertyName(staticAttribute.interface.bind()), lazy: true),
            projection: projection, to: writer)
    }
}

fileprivate func writeComposableInitializers(
        _ classDefinition: ClassDefinition, defaultInterface: BoundInterface,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    let defaultInterfaceABIName = try CAbi.mangleName(type: defaultInterface.asBoundType)
    // public init(_transferringRef comPointer: UnsafeMutablePointer<CWinRTComponent.SWRT_IFoo>) {
    //     super.init(_transferringRef: IInspectablePointer.cast(comPointer))
    // }
    let param = SwiftParam(label: "_transferringRef", name: "comPointer",
        type: .unsafeMutablePointer(to: .chain(projection.abiModuleName, defaultInterfaceABIName)))
    writer.writeInit(visibility: .public, params: [param]) { writer in
        writer.writeStatement("super.init(_transferringRef: IInspectablePointer.cast(comPointer))")
    }

    let factoryInterfaces = try classDefinition.getAttributes(ComposableAttribute.self).map { $0.factory }
    if !factoryInterfaces.isEmpty {
        // public init<Interface>(_compose: Bool, _factory: ComposableFactory<Interface>) throws {
        writer.writeInit(visibility: .public,
                override: true,
                genericParams: [ "Interface" ],
                params: [ SwiftParam(name: "_compose", type: .bool),
                          SwiftParam(name: "_factory", type: .identifier("ComposableFactory", genericArgs: [ .identifier("Interface") ])) ],
                throws: true) { writer in
            writer.writeStatement("try super.init(_compose: _compose, _factory: _factory)")
        }
    }

    for factoryInterface in factoryInterfaces {
        writer.writeCommentLine(try WinRTTypeName.from(type: factoryInterface.bindType()).description)
        try SecondaryInterfaces.writeDeclaration(
            factoryInterface.bind(), staticOf: classDefinition, projection: projection, to: writer)
        let propertyName = SecondaryInterfaces.getPropertyName(factoryInterface.bind())

        for method in factoryInterface.methods {
            // The last 2 params should be the IInspectable outer and inner pointers
            let (params, returnParam) = try projection.getParamProjections(method: method, genericTypeArgs: [])
            try writer.writeInit(
                    documentation: try projection.getDocumentationComment(method),
                    visibility: .public,
                    convenience: true,
                    params: params.dropLast(2).map { $0.toSwiftParam() },
                    throws: true) { writer in
                let output = writer.output
                let composeCondition = "Self.self != \(try projection.toTypeName(classDefinition)).self"
                try output.writeIndentedBlock(header: "try self.init(_compose: \(composeCondition)) {", footer: "}") {
                    let outerObjectParamName = params[params.count - 2].name
                    let innerObjectParamName = params[params.count - 1].name
                    output.writeFullLine("(\(outerObjectParamName), \(innerObjectParamName): inout IInspectablePointer?) in")
                    try writeInteropMethodCall(
                        name: SwiftProjection.toInteropMethodName(method), params: params, returnParam: returnParam,
                        thisPointer: .init(name: "Self.\(propertyName)", lazy: true),
                        projection: projection, to: writer.output)
                }
            }
        }
    }
}

fileprivate func writeActivationFactoryInitializers(
        _ classDefinition: ClassDefinition,
        activationFactory: InterfaceDefinition,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    writer.writeCommentLine(try WinRTTypeName.from(type: activationFactory.bindType()).description)
    try SecondaryInterfaces.writeDeclaration(
        activationFactory.bind(), staticOf: classDefinition, projection: projection, to: writer)
    let propertyName = SecondaryInterfaces.getPropertyName(activationFactory.bind())
    for method in activationFactory.methods {
        let (params, returnParam) = try projection.getParamProjections(method: method, genericTypeArgs: [])
        try writer.writeInit(
                documentation: try projection.getDocumentationComment(method),
                visibility: .public,
                convenience: true,
                params: params.map { $0.toSwiftParam() },
                throws: true) { writer in

            // Activation factory interop methods are special-cased to return the raw factory pointer,
            // so we can initialize our instance with it.
            let output = writer.output
            output.write("self.init(_transferringRef: ")
            try writeInteropMethodCall(
                name: SwiftProjection.toInteropMethodName(method), params: params, returnParam: returnParam,
                thisPointer: .init(name: "Self.\(propertyName)", lazy: true),
                projection: projection, to: writer.output)
            output.write(")")
            output.endLine()
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
    try SecondaryInterfaces.writeDeclaration(
        interfaceName: "IActivationFactory", abiStructType: .chain(projection.abiModuleName, CAbi.iactivationFactoryName),
        iid: iactivationFactoryID, staticOf: classDefinition, projection: projection, to: writer)
    let propertyName = SecondaryInterfaces.getPropertyName(interfaceName: "IActivationFactory")

    try writer.writeInit(visibility: .public, convenience: true, throws: true) { writer in
        let projectionClassName = try projection.toProjectionTypeName(classDefinition)
        writer.writeStatement("self.init(_transferringRef: try Self.\(propertyName)"
            + ".activateInstance(projection: \(projectionClassName).self))")
    }
}