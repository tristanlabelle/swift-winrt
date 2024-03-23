import CodeWriters
import Collections
import DotNetMetadata
import ProjectionModel
import WindowsMetadata
import struct Foundation.UUID

internal func writeClassDefinition(_ classDefinition: ClassDefinition, projection: SwiftProjection, to writer: SwiftSourceFileWriter) throws {
    let composable = try classDefinition.hasAttribute(ComposableAttribute.self)
    let interfaces = try ClassInterfaces(of: classDefinition, composable: composable)
    let typeName = try projection.toTypeName(classDefinition)

    if interfaces.default != nil {
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
                documentation: projection.getDocumentationComment(classDefinition),
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
                documentation: projection.getDocumentationComment(classDefinition),
                visibility: SwiftProjection.toVisibility(classDefinition.visibility),
                name: typeName) { writer in
            try writeClassMembers(
                classDefinition, interfaces: interfaces, composable: false,
                projection: projection, to: writer)
        }
    }
}

fileprivate struct ClassInterfaces {
    var hasDefaultFactory = false
    var factories: [InterfaceDefinition] = []
    var `default`: BoundInterface? = nil
    var secondary: [Secondary] = []
    var `static`: [InterfaceDefinition] = []

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

        `static` = try classDefinition.getAttributes(StaticAttribute.self).map { $0.interface }
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

    if composable {
        let overridableInterfaces = interfaces.secondary.compactMap { $0.overridable ? $0.interface : nil }
        if !overridableInterfaces.isEmpty {
            writer.writeMarkComment("Override support")
            try writeClassOverrideSupport(classDefinition, interfaces: overridableInterfaces, projection: projection, to: writer)
        }
    }
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
        let thisPointer: ThisPointer = composable
            ? .init(name: SecondaryInterfaces.getPropertyName(defaultInterface), lazy: true)
            : .init(name: "_interop")
        try writeInterfaceImplementation(
            abiType: defaultInterface.asBoundType, classDefinition: classDefinition,
            thisPointer: thisPointer, projection: projection, to: writer)
    }

    for secondaryInterface in interfaces.secondary {
        if secondaryInterface.interface.definition.methods.isEmpty { continue }
        try writeMarkComment(forInterface: secondaryInterface.interface, to: writer)
        try writeInterfaceImplementation(
            abiType: secondaryInterface.interface.asBoundType,
            classDefinition: classDefinition,
            overridable: secondaryInterface.overridable,
            thisPointer: .init(name: SecondaryInterfaces.getPropertyName(secondaryInterface.interface), lazy: true),
            projection: projection, to: writer)
    }

    for staticInterface in interfaces.static {
        if staticInterface.methods.isEmpty { continue }
        try writeMarkComment(forInterface: staticInterface.bind(), to: writer)
        try writeInterfaceImplementation(
            abiType: staticInterface.bindType(), classDefinition: classDefinition, static: true,
            thisPointer: .init(name: SecondaryInterfaces.getPropertyName(staticInterface.bind()), lazy: true),
            projection: projection, to: writer)
    }
}

fileprivate func writeClassInterfaceProperties(
        _ classDefinition: ClassDefinition, interfaces: ClassInterfaces, composable: Bool,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    // Instance properties, initializers and deinit
    if composable, let defaultInterface = interfaces.default {
        try SecondaryInterfaces.writeDeclaration(defaultInterface, composable: composable, projection: projection, to: writer)
    }

    for secondaryInterface in interfaces.secondary {
        try SecondaryInterfaces.writeDeclaration(secondaryInterface.interface, composable: composable, projection: projection, to: writer)
    }

    if composable, let defaultInterface = interfaces.default {
        try writeSupportComposableInitializers(defaultInterface: defaultInterface, projection: projection, to: writer)
    }

    // Static properties
    if interfaces.hasDefaultFactory {
        try SecondaryInterfaces.writeDeclaration(
            interfaceName: "IActivationFactory", abiStructType: .chain(projection.abiModuleName, CAbi.iactivationFactoryName),
            staticOf: classDefinition, projection: projection, to: writer)
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

fileprivate func writeClassOverrideSupport(
        _ classDefinition: ClassDefinition, interfaces: [BoundInterface],
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    let outerPropertySuffix = "outer"

    for interface in interfaces {
        // private var _istringable_outer: COM.COMExportedInterface = .uninitialized
        writer.writeStoredProperty(
            visibility: .private, declarator: .var,
            name: SecondaryInterfaces.getPropertyName(interface, suffix: outerPropertySuffix),
            type: SupportModules.COM.comExportedInterface, initialValue: ".uninitialized")
    }

    // public override func _queryOverridesInterfacePointer(_ id: COM.COMInterfaceID) throws -> COM.IUnknownPointer? {
    try writer.writeFunc(
            visibility: .public, override: true, name: "_queryOverridesInterfacePointer",
            params: [ .init(label: "_", name: "id", type: SupportModules.COM.comInterfaceID) ], throws: true,
            returnType: .optional(wrapped: SupportModules.COM.iunknownPointer)) { writer in
        for interface in interfaces {
            // if id == SWRT_IFoo.iid {
            let abiSwiftType = try projection.toABIType(interface.asBoundType)
            try writer.writeBracedBlock("if id == \(abiSwiftType).iid") { writer in
                // if !_ifooOverrides_outer.isInitialized {
                //     _ifooOverrides_outer = COMExportedInterface(
                //         swiftObject: self, virtualTable: &FooProjection.VirtualTables.ifooOverrides)
                // }
                let outerPropertyName = SecondaryInterfaces.getPropertyName(interface, suffix: outerPropertySuffix)
                try writer.writeBracedBlock("if !\(outerPropertyName).isInitialized") { writer in
                    let projectionTypeName = try projection.toProjectionTypeName(classDefinition)
                    let vtablePropertyName = Casing.pascalToCamel(interface.definition.nameWithoutGenericSuffix)
                    writer.writeStatement("\(outerPropertyName) = \(SupportModules.COM.comExportedInterface)(\n"
                        + "swiftObject: self, virtualTable: &\(projectionTypeName).VirtualTables.\(vtablePropertyName))")
                }

                // return _iminimalUnsealedClassOverridesOuter.unknownPointer.addingRef()
                writer.writeReturnStatement(value: "\(outerPropertyName).toCOM().detach()")
            }
        }
        writer.writeReturnStatement(value: "nil")
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
    let propertyName = SecondaryInterfaces.getPropertyName(factoryInterface.bind())

    for method in factoryInterface.methods {
        // The last 2 params should be the IInspectable outer and inner pointers
        let (params, returnParam) = try projection.getParamProjections(method: method, genericTypeArgs: [])
        try writer.writeInit(
                documentation: try projection.getDocumentationComment(abiMember: method, classDefinition: classDefinition),
                visibility: .public,
                params: params.dropLast(2).map { $0.toSwiftParam() },
                throws: true) { writer in
            let output = writer.output
            let composeCondition = "Self.self != \(try projection.toTypeName(classDefinition)).self"
            try output.writeIndentedBlock(header: "try super.init(_compose: \(composeCondition)) {", footer: "}") {
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
        writer.writeStatement("self.init(_wrapping: \(SupportModules.COM.comReference)(transferringRef: try Self.\(propertyName)"
            + ".activateInstance(projection: \(projectionClassName).self)))")
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
                documentation: try projection.getDocumentationComment(abiMember: method, classDefinition: classDefinition),
                visibility: .public,
                convenience: true,
                params: params.map { $0.toSwiftParam() },
                throws: true) { writer in

            // Activation factory interop methods are special-cased to return the raw factory pointer,
            // so we can initialize our instance with it.
            let output = writer.output
            output.write("self.init(_wrapping: \(SupportModules.COM.comReference)(transferringRef: ")
            try writeInteropMethodCall(
                name: SwiftProjection.toInteropMethodName(method), params: params, returnParam: returnParam,
                thisPointer: .init(name: "Self.\(propertyName)", lazy: true),
                projection: projection, to: writer.output)
            output.write("))")
            output.endLine()
        }
    }
}

fileprivate func writeSupportComposableInitializers(
        defaultInterface: BoundInterface, projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    // public init(_transferringRef pointer: UnsafeMutablePointer<CWinRTComponent.SWRT_IFoo>) {
    //     super.init(_transferringRef: .init(OpaquePointer(pointer))
    // }
    // Should use a COMReference<> but this runs into compiler bugs.
    let pointerType: SwiftType = .unsafeMutablePointer(to: try projection.toABIType(defaultInterface.asBoundType))
    let param = SwiftParam(label: "_transferringRef", name: "pointer", type: pointerType)
    writer.writeInit(visibility: .public, params: [param]) { writer in
        writer.writeStatement("super.init(_transferringRef: .init(OpaquePointer(pointer)))")
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
