import CodeWriters
import Collections
import DotNetMetadata
import ProjectionModel
import WindowsMetadata
import struct Foundation.UUID

internal func writeClassDefinition(_ classDefinition: ClassDefinition, projection: SwiftProjection, to writer: SwiftSourceFileWriter) throws {
    let composable = try classDefinition.hasAttribute(ComposableAttribute.self)
    let interfaces = try ClassInterfaces(of: classDefinition, composable: composable)

    if interfaces.default != nil {
        let typeName = try projection.toTypeName(classDefinition)
        let projectionTypeName = try projection.toProjectionTypeName(classDefinition)
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
            try writeClassMembers(
                classDefinition, interfaces: interfaces, composable: composable,
                projection: projection, to: writer)
        }
    }
    else {
        assert(classDefinition.isStatic)
        assert(classDefinition.baseInterfaces.isEmpty)

        try writer.writeEnum(
                visibility: SwiftProjection.toVisibility(classDefinition.visibility),
                name: try projection.toTypeName(classDefinition)) { writer in
            try writeClassMembers(
                classDefinition, interfaces: interfaces, composable: false,
                projection: projection, to: writer)
        }
    }
}

fileprivate struct ClassInterfaces {
    var hasDefaultFactory = false
    var factories: [InterfaceDefinition] = []
    var `static`: [InterfaceDefinition] = []
    var `default`: BoundInterface? = nil
    var secondary: [Secondary] = []

    struct Secondary {
        var interface: BoundInterface
        var overridable: Bool
        var protected: Bool
    }

    public init(of classDefinition: ClassDefinition, composable: Bool) throws {
        if composable {
            factories = try classDefinition.getAttributes(ComposableAttribute.self).map { $0.factory }
            hasDefaultFactory = false
        }
        else {
            let activatableAttributes = try classDefinition.getAttributes(ActivatableAttribute.self)
            factories = activatableAttributes.compactMap { $0.factory }
            hasDefaultFactory = activatableAttributes.count > factories.count
        }

        `static` = try classDefinition.getAttributes(StaticAttribute.self).map { $0.interface }

        for baseInterface in classDefinition.baseInterfaces {
            if try baseInterface.hasAttribute(DefaultAttribute.self) {
                `default` = try baseInterface.interface
            }
            else {
                let overridable = try baseInterface.hasAttribute(OverridableAttribute.self)
                let protected = try baseInterface.hasAttribute(ProtectedAttribute.self)
                secondary.append(Secondary(interface: try baseInterface.interface, overridable: overridable, protected: protected))
            }
        }
    }
}

fileprivate func writeClassMembers(
        _ classDefinition: ClassDefinition, interfaces: ClassInterfaces, composable: Bool,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    try writeGenericTypeAliases(interfaces: classDefinition.baseInterfaces.map { try $0.interface }, projection: projection, to: writer)

    try writeClassInterfaceImplementations(
        classDefinition, interfaces: interfaces, composable: composable,
        projection: projection, to: writer)

    writer.writeMarkComment("Implementation details")
    try writeClassInterfaceProperties(
        classDefinition, interfaces: interfaces, composable: composable,
        projection: projection, to: writer)
}

fileprivate func writeClassInterfaceImplementations(
        _ classDefinition: ClassDefinition, interfaces: ClassInterfaces, composable: Bool,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    if interfaces.hasDefaultFactory {
        writeMarkComment(forInterface: "IActivationFactory", to: writer)
        try writeDefaultActivatableInitializer(classDefinition, projection: projection, to: writer)
    }

    for factoryInterface in interfaces.factories {
        if factoryInterface.methods.isEmpty { continue }
        try writeMarkComment(forInterface: factoryInterface.bind(), to: writer)
        if composable {
            try writeComposableInitializers(classDefinition, factoryInterface: factoryInterface, projection: projection, to: writer)
        }
        else {
            try writeActivatableInitializers(classDefinition, activationFactory: factoryInterface, projection: projection, to: writer)
        }
    }

    if let defaultInterface = interfaces.default, !defaultInterface.definition.methods.isEmpty {
        try writeMarkComment(forInterface: defaultInterface, to: writer)
        let thisPointer: ThisPointer = composable ? .init(name: "_interop")
            : .init(name: SecondaryInterfaces.getPropertyName(defaultInterface), lazy: true)
        try writeInterfaceImplementation(
            interfaceOrDelegate: defaultInterface.asBoundType,
            thisPointer: thisPointer,
            projection: projection, to: writer)
    }

    for secondaryInterface in interfaces.secondary {
        if secondaryInterface.interface.definition.methods.isEmpty { continue }
        try writeMarkComment(forInterface: secondaryInterface.interface, to: writer)
        try writeInterfaceImplementation(
            interfaceOrDelegate: secondaryInterface.interface.asBoundType,
            overridable: secondaryInterface.overridable,
            thisPointer: .init(name: SecondaryInterfaces.getPropertyName(secondaryInterface.interface), lazy: true),
            projection: projection, to: writer)
    }

    for staticInterface in interfaces.static {
        if staticInterface.methods.isEmpty { continue }
        try writeMarkComment(forInterface: staticInterface.bind(), to: writer)
        try writeInterfaceImplementation(
            interfaceOrDelegate: staticInterface.bindType(), static: true,
            thisPointer: .init(name: SecondaryInterfaces.getPropertyName(staticInterface.bind()), lazy: true),
            projection: projection, to: writer)
    }
}

fileprivate func writeClassInterfaceProperties(
        _ classDefinition: ClassDefinition, interfaces: ClassInterfaces, composable: Bool,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    // Instance properties, initializers and deinit
    if let defaultInterface = interfaces.default {
        try SecondaryInterfaces.writeDeclaration(defaultInterface, projection: projection, to: writer)
    }

    for secondaryInterface in interfaces.secondary {
        try SecondaryInterfaces.writeDeclaration(secondaryInterface.interface, projection: projection, to: writer)
    }

    if composable, let defaultInterface = interfaces.default {
        try writeSupportComposableInitializers(defaultInterface: defaultInterface, projection: projection, to: writer)
    }

    if interfaces.default != nil || !interfaces.secondary.isEmpty {
        writer.writeDeinit { writer in
            if let defaultInterface = interfaces.default {
                SecondaryInterfaces.writeCleanup(defaultInterface, to: writer)
            }

            for secondaryInterface in interfaces.secondary {
                SecondaryInterfaces.writeCleanup(secondaryInterface.interface, to: writer)
            }
        }
    }

    // Static properties
    if interfaces.hasDefaultFactory {
        // TODO: Move GUID to COMInterop<SWRT_IActivationFactory>
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
    }

    for factoryInterface in interfaces.factories {
        try SecondaryInterfaces.writeDeclaration(
            factoryInterface.bind(), staticOf: classDefinition, projection: projection, to: writer)
    }

    for staticInterface in interfaces.static {
        try SecondaryInterfaces.writeDeclaration(
            staticInterface.bind(), staticOf: classDefinition, projection: projection, to: writer)
    }
}

fileprivate func writeMarkComment(forInterface interface: BoundInterface, to writer: SwiftTypeDefinitionWriter) throws {
    let interfaceName = try WinRTTypeName.from(type: interface.asBoundType).description
    writeMarkComment(forInterface: interfaceName, to: writer)
}

fileprivate func writeMarkComment(forInterface interfaceName: String, to writer: SwiftTypeDefinitionWriter) {
    writer.writeMarkComment("\(interfaceName) members")
}

fileprivate func writeComposableInitializers(
        _ classDefinition: ClassDefinition, factoryInterface: InterfaceDefinition,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    writer.writeCommentLine(try WinRTTypeName.from(type: factoryInterface.bindType()).description)
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

fileprivate func writeDefaultActivatableInitializer(
        _ classDefinition: ClassDefinition,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    try writer.writeInit(visibility: .public, convenience: true, throws: true) { writer in
        let propertyName = SecondaryInterfaces.getPropertyName(interfaceName: "IActivationFactory")
        let projectionClassName = try projection.toProjectionTypeName(classDefinition)
        writer.writeStatement("self.init(_transferringRef: try Self.\(propertyName)"
            + ".activateInstance(projection: \(projectionClassName).self))")
    }
}

fileprivate func writeActivatableInitializers(
        _ classDefinition: ClassDefinition,
        activationFactory: InterfaceDefinition,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
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

fileprivate func writeSupportComposableInitializers(
        defaultInterface: BoundInterface, projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    // public init(_transferringRef comPointer: UnsafeMutablePointer<CWinRTComponent.SWRT_IFoo>) {
    //     super.init(_transferringRef: IInspectablePointer.cast(comPointer))
    // }
    let defaultInterfaceABIName = try CAbi.mangleName(type: defaultInterface.asBoundType)
    let param = SwiftParam(label: "_transferringRef", name: "comPointer",
        type: .unsafeMutablePointer(to: .chain(projection.abiModuleName, defaultInterfaceABIName)))
    writer.writeInit(visibility: .public, params: [param]) { writer in
        writer.writeStatement("super.init(_transferringRef: IInspectablePointer.cast(comPointer))")
    }

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