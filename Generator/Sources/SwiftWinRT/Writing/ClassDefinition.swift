import CodeWriters
import Collections
import DotNetMetadata
import ProjectionModel
import WindowsMetadata
import struct Foundation.UUID

internal func writeClassDefinition(_ classDefinition: ClassDefinition, projection: Projection, to writer: SwiftSourceFileWriter) throws {
    let interfaces = try ClassInterfaces(of: classDefinition)
    let typeName = try projection.toTypeName(classDefinition)

    if classDefinition.isStatic {
        assert(classDefinition.baseInterfaces.isEmpty)

        try writer.writeEnum(
                documentation: projection.getDocumentationComment(classDefinition),
                attributes: projection.getAttributes(classDefinition),
                visibility: Projection.toVisibility(classDefinition.visibility),
                name: typeName) { writer in
            try writeClassMembers(
                classDefinition, interfaces: interfaces, projection: projection, to: writer)
        }

        return
    }

    // Both composable and activatable classes can have a base class
    let base: SwiftType
    if let baseClassDefinition = try getRuntimeClassBase(classDefinition) {
        base = try projection.toTypeReference(baseClassDefinition.bindType())
    } else {
        base = try classDefinition.isSealed
            ? SupportModules.WinRT.winRTImport(of: projection.toBindingType(classDefinition))
            : SupportModules.WinRT.composableClass
    }

    var protocolConformances: [SwiftType] = []
    for baseInterface in classDefinition.baseInterfaces {
        let interfaceDefinition = try baseInterface.interface.definition
        guard interfaceDefinition.isPublic else { continue }
        protocolConformances.append(.named(try projection.toProtocolName(interfaceDefinition)))
    }

    if (try? classDefinition.findAttribute(MarshalingBehaviorAttribute.self))?.type == .agile {
        // SwiftType cannot represent attributed types, so abuse the type name string.
        protocolConformances.append(.named("@unchecked Sendable"))
    }

    try writer.writeClass(
            documentation: projection.getDocumentationComment(classDefinition),
            attributes: projection.getAttributes(classDefinition),
            visibility: Projection.toVisibility(classDefinition.visibility, inheritableClass: !classDefinition.isSealed),
            final: classDefinition.isSealed, name: typeName, base: base, protocolConformances: protocolConformances) { writer in
        try writeClassMembers(classDefinition, interfaces: interfaces, projection: projection, to: writer)
    }
}

fileprivate func getRuntimeClassBase(_ classDefinition: ClassDefinition) throws -> ClassDefinition? {
    guard let baseClassDefinition = try classDefinition.base?.definition as? ClassDefinition,
        try baseClassDefinition != classDefinition.context.coreLibrary.systemObject else { return nil }
    return baseClassDefinition
}

fileprivate func hasComposableBase(_ classDefinition: ClassDefinition) throws -> Bool {
    try !classDefinition.isSealed || getRuntimeClassBase(classDefinition) != nil
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

    public init(of classDefinition: ClassDefinition) throws {
        `static` = try classDefinition.getAttributes(StaticAttribute.self).map { $0.interface }

        guard !classDefinition.isStatic else {
            factories = []
            hasDefaultFactory = false
            return
        }

        if classDefinition.isSealed {
            let activatableAttributes = try classDefinition.getAttributes(ActivatableAttribute.self)
            factories = activatableAttributes.compactMap { $0.factory }
            hasDefaultFactory = activatableAttributes.count > factories.count
        }
        else {
            factories = try classDefinition.getAttributes(ComposableAttribute.self).map { $0.factory }
            hasDefaultFactory = false
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
    }
}

fileprivate func writeClassMembers(
        _ classDefinition: ClassDefinition, interfaces: ClassInterfaces,
        projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    try writeGenericTypeAliases(interfaces: classDefinition.baseInterfaces.map { try $0.interface }, projection: projection, to: writer)

    try writeInterfaceImplementations(
        classDefinition, interfaces: interfaces,
        projection: projection, to: writer)

    writer.writeMarkComment("Implementation details")

    if let defaultInterface = interfaces.default {
        // init(_wrapping:)
        try writeDelegatingWrappingInitializer(
            classDefinition: classDefinition, defaultInterface: defaultInterface, projection: projection, to: writer)

        // Composable initializers
        if !classDefinition.isSealed {
            try writeDelegatingComposableInitializer(defaultInterface: defaultInterface, projection: projection, to: writer)
        }
    }

    // var _lazyFoo: COM.COMReference<SWRT_IFoo>.Optional = .none
    try writeSecondaryInterfaces(classDefinition, interfaces: interfaces, projection: projection, to: writer)
}

fileprivate func writeInterfaceImplementations(
        _ classDefinition: ClassDefinition, interfaces: ClassInterfaces,
        projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    if interfaces.hasDefaultFactory {
        try writeDefaultActivatableInitializer(classDefinition, projection: projection, to: writer)
    }

    for factoryInterface in interfaces.factories {
        if factoryInterface.methods.isEmpty { continue }

        if try factoryInterface.findAttribute(ExclusiveToAttribute.self) == nil {
            try writeMarkComment(forInterface: factoryInterface.bind(), to: writer)
        }

        if classDefinition.isSealed {
            try writeActivatableInitializers(classDefinition, activationFactory: factoryInterface, projection: projection, to: writer)
        }
        else {
            try writeComposableInitializers(classDefinition, factoryInterface: factoryInterface, projection: projection, to: writer)
        }
    }

    if let defaultInterface = interfaces.default, !defaultInterface.definition.methods.isEmpty {
        if try defaultInterface.definition.findAttribute(ExclusiveToAttribute.self) == nil {
            try writeMarkComment(forInterface: defaultInterface, to: writer)
        }

        let thisPointer: ThisPointer = try classDefinition.isSealed && getRuntimeClassBase(classDefinition) == nil
            ? .init(name: "_interop")
            : .init(name: SecondaryInterfaces.getPropertyName(defaultInterface), lazy: true)
        try writeMemberDefinitions(
            abiType: defaultInterface.asBoundType, classDefinition: classDefinition,
            thisPointer: thisPointer, projection: projection, to: writer)
    }

    if !classDefinition.isSealed, interfaces.secondary.contains(where: { $0.overridable }) {
        // open override var supportsOverrides: Bool { Self.self != MyClass.self }
        try writer.writeComputedProperty(
            visibility: .open,
            class: true,
            override: true,
            name: SupportModules.WinRT.composableClass_supportsOverrides,
            type: .bool,
            get: {
                $0.writeStatement("Self.self != \(try projection.toTypeName(classDefinition)).self")
            })
    }

    for secondaryInterface in interfaces.secondary {
        if secondaryInterface.interface.definition.methods.isEmpty { continue }

        if try secondaryInterface.interface.definition.findAttribute(ExclusiveToAttribute.self) == nil {
            try writeMarkComment(forInterface: secondaryInterface.interface, to: writer)
        }

        try writeMemberDefinitions(
            abiType: secondaryInterface.interface.asBoundType,
            classDefinition: classDefinition,
            overridable: secondaryInterface.overridable,
            thisPointer: .init(name: SecondaryInterfaces.getPropertyName(secondaryInterface.interface), lazy: true),
            projection: projection, to: writer)
    }

    for staticInterface in interfaces.static {
        if staticInterface.methods.isEmpty { continue }

        if try staticInterface.findAttribute(ExclusiveToAttribute.self) == nil {
            try writeMarkComment(forInterface: staticInterface.bind(), to: writer)
        }

        try writeMemberDefinitions(
            abiType: staticInterface.bindType(), classDefinition: classDefinition, static: true,
            thisPointer: .init(name: SecondaryInterfaces.getPropertyName(staticInterface.bind()), lazy: true),
            projection: projection, to: writer)
    }
}

fileprivate func writeSecondaryInterfaces(
        _ classDefinition: ClassDefinition, interfaces: ClassInterfaces,
        projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    // Instance properties
    if let defaultInterface = interfaces.default, try hasComposableBase(classDefinition) {
        // Inheriting from ComposableClass, we need a property for the default interface
        try SecondaryInterfaces.writeDeclaration(
            defaultInterface, static: false, composable: !classDefinition.isSealed,
            projection: projection, to: writer)
    }

    for secondaryInterface in interfaces.secondary {
        try SecondaryInterfaces.writeDeclaration(
            secondaryInterface.interface, static: false, composable: !classDefinition.isSealed,
            projection: projection, to: writer)
    }

    // Static properties
    try SecondaryInterfaces.writeActivationFactoryDeclaration(
        classDefinition: classDefinition, projection: projection, to: writer)

    for factoryInterface in interfaces.factories {
        try SecondaryInterfaces.writeDeclaration(factoryInterface.bind(), static: true, projection: projection, to: writer)
    }

    for staticInterface in interfaces.static {
        try SecondaryInterfaces.writeDeclaration(staticInterface.bind(), static: true, projection: projection, to: writer)
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
        projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    let propertyName = SecondaryInterfaces.getPropertyName(factoryInterface.bind())

    let baseClassDefinition = try getRuntimeClassBase(classDefinition)
    let outerObjectType = try projection.toBindingType(classDefinition).member("OuterObject")

    for method in factoryInterface.methods {
        // Swift requires "override" on initializers iff the same initializer is defined in the direct base class
        let `override` = try baseClassDefinition.map {
            try hasComposableConstructor(classDefinition: $0, paramTypes: method.params.dropLast(2).map { try $0.type })
        } ?? false

        // The last 2 params should be the IInspectable outer and inner pointers
        let (params, returnParam) = try projection.getParamBindings(method: method, genericTypeArgs: [], abiKind: .composableFactory)

        let docs = try projection.getDocumentationComment(method, classFactoryKind: .composable, classDefinition: classDefinition)

        try writer.writeInit(
                documentation: docs,
                attributes: projection.getAttributes(method),
                visibility: .public,
                override: `override`,
                params: params.dropLast(2).map { $0.toSwiftParam() }, // Drop inner and outer pointer params
                throws: true) { writer in
            let output = writer.output
            try output.writeLineBlock(header: "try super.init(_outer: \(outerObjectType).self) {", footer: "}") {
                let outerObjectParamName = params[params.count - 2].name
                let innerObjectParamName = params[params.count - 1].name
                output.writeFullLine("(\(outerObjectParamName), \(innerObjectParamName): inout IInspectablePointer?) in")
                try writeInteropMethodCall(
                    name: Projection.toInteropMethodName(method), params: params, returnParam: returnParam,
                    thisPointer: .init(name: "Self.\(propertyName)", lazy: true),
                    projection: projection, to: writer.output)
            }
        }
    }
}

fileprivate func hasComposableConstructor(classDefinition: ClassDefinition, paramTypes: [TypeNode]) throws -> Bool {
    for composableAttribute in try classDefinition.getAttributes(ComposableAttribute.self) {
        for composableConstructor in composableAttribute.factory.methods {
            // Ignore the last 2 parameters (IInspectable outer and inner pointers)
            guard try composableConstructor.arity == (paramTypes.count + 2) else { continue }
            if try composableConstructor.params.dropLast(2).map({ try $0.type }) == paramTypes { return true }
        }
    }

    return false
}

fileprivate func writeDefaultActivatableInitializer(
        _ classDefinition: ClassDefinition,
        projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    let constructor = classDefinition.findConstructor(arity: 0, inherited: false)
    let baseClassDefinition = try getRuntimeClassBase(classDefinition)
    let isOverriding = try baseClassDefinition.map {
            try hasComposableConstructor(classDefinition: $0, paramTypes: [])
        } ?? false

    try writer.writeInit(
            documentation: constructor.flatMap { try projection.getDocumentationComment($0) },
            attributes: constructor.map { try projection.getAttributes($0) } ?? [],
            visibility: .public,
            override: isOverriding,
            throws: true) { writer in
        let propertyName = SecondaryInterfaces.getPropertyName(interfaceName: "IActivationFactory")
        let bindingType = try projection.toBindingType(classDefinition)
        writer.writeStatement("let _instance = \(SupportModules.COM.comReference)(transferringRef: try Self.\(propertyName)"
            + ".activateInstance(binding: \(bindingType).self))")
        if try hasComposableBase(classDefinition) {
            writer.writeStatement("super.init(_wrapping: _instance.cast()) // Transitively casts down to IInspectable")
        }
        else {
            writer.writeStatement("super.init(_wrapping: consume _instance)")
        }
    }
}

fileprivate func writeActivatableInitializers(
        _ classDefinition: ClassDefinition,
        activationFactory: InterfaceDefinition,
        projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    let propertyName = SecondaryInterfaces.getPropertyName(activationFactory.bind())

    let baseClassDefinition = try getRuntimeClassBase(classDefinition)
    let hasComposableBase = try hasComposableBase(classDefinition)

    for method in activationFactory.methods {
        let (params, returnParam) = try projection.getParamBindings(method: method, genericTypeArgs: [], abiKind: .activationFactory)
        let docs = try projection.getDocumentationComment(
            method, classFactoryKind: .activatable, classDefinition: classDefinition)
        let isOverriding = try baseClassDefinition.map {
                try hasComposableConstructor(classDefinition: $0, paramTypes: method.params.map { try $0.type })
            } ?? false

        try writer.writeInit(
                documentation: docs,
                attributes: projection.getAttributes(method),
                visibility: .public,
                override: isOverriding,
                params: params.map { $0.toSwiftParam() },
                throws: true) { writer in

            // Activation factory interop methods are special-cased to return a COMReference<T> (ABI representation),
            // so we can initialize our instance with it.
            let output = writer.output
            output.write("let _instance = ")
            try writeInteropMethodCall(
                name: Projection.toInteropMethodName(method), params: params, returnParam: returnParam,
                thisPointer: .init(name: "Self.\(propertyName)", lazy: true),
                projection: projection, to: writer.output)
            output.endLine()
            if hasComposableBase {
                writer.writeStatement("super.init(_wrapping: _instance.cast()) // Transitively casts down to IInspectable")
            }
            else {
                writer.writeStatement("super.init(_wrapping: consume _instance)")
            }
        }
    }
}

/// Writes the initializer wraps a COM reference and delegates to the base composable initializer.
fileprivate func writeDelegatingWrappingInitializer(
        classDefinition: ClassDefinition, defaultInterface: BoundInterface,
        projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    // public init(_wrapping inner: COMReference<CWinRTComponent.SWRT_IFoo>) {
    //     super.init(_wrapping: inner.cast())
    // }
    let comReferenceType: SwiftType = SupportModules.COM.comReference(to: try projection.toABIType(defaultInterface.asBoundType))
    let param = SwiftParam(label: "_wrapping", name: "inner", consuming: true, type: comReferenceType)
    let hasComposableBase = try hasComposableBase(classDefinition)
    writer.writeInit(
            visibility: .public,
            required: !hasComposableBase, // use the 'required' modifier to override a required initializer
            params: [param]) { writer in
        if hasComposableBase {
            writer.writeStatement("super.init(_wrapping: inner.cast()) // Transitively casts down to IInspectable")
        }
        else {
            writer.writeStatement("super.init(_wrapping: consume inner)")
        }
    }
}

fileprivate func writeDelegatingComposableInitializer(
        defaultInterface: BoundInterface, projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    // public init<ABIStruct>(_outer: OuterObject.Type, _factory: ComposableFactory<ABIStruct>) throws {
    writer.writeInit(visibility: .public,
            override: true,
            genericParams: [ "ABIStruct" ],
            params: [
                SwiftParam(name: "_outer", type: .named("OuterObject").member("Type")),
                SwiftParam(name: "_factory", type: .named("ComposableFactory", genericArgs: [ .named("ABIStruct") ]))
            ],
            throws: true) { writer in
        writer.writeStatement("try super.init(_outer: _outer, _factory: _factory)")
    }
}
