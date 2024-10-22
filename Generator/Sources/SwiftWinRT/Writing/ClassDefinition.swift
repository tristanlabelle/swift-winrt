import CodeWriters
import Collections
import DotNetMetadata
import ProjectionModel
import WindowsMetadata
import struct Foundation.UUID

internal func writeClassDefinition(_ classDefinition: ClassDefinition, projection: Projection, to writer: SwiftSourceFileWriter) throws {
    let classKind = try ClassKind(classDefinition)
    let interfaces = try ClassInterfaces(of: classDefinition, kind: classKind)
    let typeName = try projection.toTypeName(classDefinition)

    if classKind != .static {
        let bindingTypeName = try projection.toBindingTypeName(classDefinition)
        assert(classDefinition.isSealed || classKind.isComposable)
        assert(!classDefinition.isAbstract || classKind.isComposable)

        let base: SwiftType
        switch classKind {
            case .composable(base: .some(let baseClassDefinition)):
                base = try projection.toType(baseClassDefinition.bindType(), nullable: false)
            case .composable(base: nil):
                base = SupportModules.WinRT.composableClass
            default:
                base = SupportModules.WinRT.winRTImport(of: .identifier(bindingTypeName))
        }

        var protocolConformances: [SwiftType] = []
        for baseInterface in classDefinition.baseInterfaces {
            let interfaceDefinition = try baseInterface.interface.definition
            guard interfaceDefinition.isPublic else { continue }
            protocolConformances.append(.identifier(try projection.toProtocolName(interfaceDefinition)))
        }

        if (try? classDefinition.findAttribute(MarshalingBehaviorAttribute.self))?.type == .agile {
            // SwiftType cannot represent attributed types, so abuse the type name string.
            protocolConformances.append(.identifier("@unchecked Sendable"))
        }

        try writer.writeClass(
                documentation: projection.getDocumentationComment(classDefinition),
                visibility: Projection.toVisibility(classDefinition.visibility, inheritableClass: !classDefinition.isSealed),
                final: classDefinition.isSealed, name: typeName, base: base, protocolConformances: protocolConformances) { writer in
            try writeClassMembers(
                classDefinition, interfaces: interfaces, kind: classKind,
                projection: projection, to: writer)
        }
    }
    else {
        assert(classDefinition.isStatic)
        assert(classDefinition.baseInterfaces.isEmpty)

        try writer.writeEnum(
                documentation: projection.getDocumentationComment(classDefinition),
                visibility: Projection.toVisibility(classDefinition.visibility),
                name: typeName) { writer in
            try writeClassMembers(
                classDefinition, interfaces: interfaces, kind: .static,
                projection: projection, to: writer)
        }
    }
}

fileprivate enum ClassKind: Equatable {
    case activatable
    case composable(base: ClassDefinition?)
    case `static`

    init(_ classDefinition: ClassDefinition) throws {
        if classDefinition.isStatic {
            self = .static
        } else if try classDefinition.hasAttribute(ComposableAttribute.self) {
            if let baseClassDefinition = try classDefinition.base?.definition as? ClassDefinition,
                    try baseClassDefinition != classDefinition.context.coreLibrary.systemObject {
                self = .composable(base: baseClassDefinition)
            } else {
                self = .composable(base: nil)
            }
        } else {
            self = .activatable
        }
    }

    public var isComposable: Bool {
        switch self {
            case .composable: return true
            default: return false
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

    public init(of classDefinition: ClassDefinition, kind: ClassKind) throws {
        switch kind {
            case .activatable:
                let activatableAttributes = try classDefinition.getAttributes(ActivatableAttribute.self)
                factories = activatableAttributes.compactMap { $0.factory }
                hasDefaultFactory = activatableAttributes.count > factories.count
            case .composable:
                factories = try classDefinition.getAttributes(ComposableAttribute.self).map { $0.factory }
                hasDefaultFactory = false
            case .static:
                factories = []
                hasDefaultFactory = false
        }

        if kind != .static {
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

        `static` = try classDefinition.getAttributes(StaticAttribute.self).map { $0.interface }
    }
}

fileprivate func writeClassMembers(
        _ classDefinition: ClassDefinition, interfaces: ClassInterfaces, kind: ClassKind,
        projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    try writeGenericTypeAliases(interfaces: classDefinition.baseInterfaces.map { try $0.interface }, projection: projection, to: writer)

    try writeClassInterfaceImplementations(
        classDefinition, interfaces: interfaces, kind: kind,
        projection: projection, to: writer)

    writer.writeMarkComment("Implementation details")
    try writeClassInterfaceProperties(
        classDefinition, interfaces: interfaces, kind: kind,
        projection: projection, to: writer)

    if kind.isComposable {
        let overridableInterfaces = interfaces.secondary.compactMap { $0.overridable ? $0.interface : nil }
        if !overridableInterfaces.isEmpty {
            writer.writeMarkComment("Override support")
            try writeClassOverrideSupport(classDefinition, interfaces: overridableInterfaces, projection: projection, to: writer)
        }
    }
}

fileprivate func writeClassInterfaceImplementations(
        _ classDefinition: ClassDefinition, interfaces: ClassInterfaces, kind: ClassKind,
        projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    if interfaces.hasDefaultFactory {
        writeMarkComment(forInterface: "IActivationFactory", to: writer)
        try writeDefaultActivatableInitializer(classDefinition, projection: projection, to: writer)
    }

    for factoryInterface in interfaces.factories {
        if factoryInterface.methods.isEmpty { continue }
        try writeMarkComment(forInterface: factoryInterface.bind(), to: writer)
        if case .composable(base: let base) = kind {
            try writeComposableInitializers(classDefinition, factoryInterface: factoryInterface, base: base, projection: projection, to: writer)
        }
        else {
            try writeActivatableInitializers(classDefinition, activationFactory: factoryInterface, projection: projection, to: writer)
        }
    }

    if let defaultInterface = interfaces.default, !defaultInterface.definition.methods.isEmpty {
        try writeMarkComment(forInterface: defaultInterface, to: writer)
        let thisPointer: ThisPointer = kind.isComposable
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
        _ classDefinition: ClassDefinition, interfaces: ClassInterfaces, kind: ClassKind,
        projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    // Instance properties, initializers and deinit
    if kind.isComposable, let defaultInterface = interfaces.default {
        try SecondaryInterfaces.writeDeclaration(
            defaultInterface, static: false, composable: kind.isComposable,
            projection: projection, to: writer)
    }

    for secondaryInterface in interfaces.secondary {
        try SecondaryInterfaces.writeDeclaration(
            secondaryInterface.interface, static: false, composable: kind.isComposable,
            projection: projection, to: writer)
    }

    if kind.isComposable, let defaultInterface = interfaces.default {
        try writeSupportComposableInitializers(defaultInterface: defaultInterface, projection: projection, to: writer)
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

fileprivate func writeClassOverrideSupport(
        _ classDefinition: ClassDefinition, interfaces: [BoundInterface],
        projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    let outerPropertySuffix = "outer"

    for interface in interfaces {
        // private var _istringable_outer: COM.COMEmbedding = .uninitialized
        writer.writeStoredProperty(
            visibility: .private, declarator: .var,
            name: SecondaryInterfaces.getPropertyName(interface, suffix: outerPropertySuffix),
            type: SupportModules.COM.comEmbedding, initialValue: ".uninitialized")
    }

    // public override func _queryOverridesInterface(_ id: COM.COMInterfaceID) throws -> COM.IUnknownReference.Optional {
    try writer.writeFunc(
            visibility: .public, override: true, name: "_queryOverridesInterface",
            params: [ .init(label: "_", name: "id", type: SupportModules.COM.comInterfaceID) ], throws: true,
            returnType: SupportModules.COM.iunknownReference_Optional) { writer in
        for interface in interfaces {
            // if id == uuidof(SWRT_IFoo.self) {
            let abiSwiftType = try projection.toABIType(interface.asBoundType)
            try writer.writeBracedBlock("if id == uuidof(\(abiSwiftType).self)") { writer in
                // if !_ifooOverrides_outer.isInitialized {
                //     _ifooOverrides_outer = COMEmbedding(
                //         swiftObject: self, virtualTable: &FooBinding.VirtualTables.ifooOverrides)
                // }
                let outerPropertyName = SecondaryInterfaces.getPropertyName(interface, suffix: outerPropertySuffix)
                try writer.writeBracedBlock("if !\(outerPropertyName).isInitialized") { writer in
                    let bindingTypeName = try projection.toBindingTypeName(classDefinition)
                    let vtablePropertyName = Casing.pascalToCamel(interface.definition.nameWithoutGenericArity)
                    writer.writeStatement("\(outerPropertyName).initialize(embedder: self,\n"
                        + "virtualTable: &\(bindingTypeName).VirtualTables.\(vtablePropertyName))")
                }

                // return .init(_iminimalUnsealedClassOverrides_outer.toCOM())
                writer.writeReturnStatement(value: ".init(\(outerPropertyName).toCOM())")
            }
        }
        writer.writeReturnStatement(value: ".none")
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
        _ classDefinition: ClassDefinition, factoryInterface: InterfaceDefinition, base: ClassDefinition?,
        projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    let propertyName = SecondaryInterfaces.getPropertyName(factoryInterface.bind())

    for method in factoryInterface.methods {
        // Swift requires "override" on initializers iff the same initializer is defined in the direct base class
        let `override` = try base != nil && hasComposableConstructor(classDefinition: base!, paramTypes: method.params.map { try $0.type })
        // The last 2 params should be the IInspectable outer and inner pointers
        let (params, returnParam) = try projection.getParamBindings(method: method, genericTypeArgs: [], abiKind: .composableFactory)
        try writer.writeInit(
                documentation: try projection.getDocumentationComment(abiMember: method, classDefinition: classDefinition),
                visibility: .public,
                override: `override`,
                params: params.dropLast(2).map { $0.toSwiftParam() }, // Drop inner and outer pointer params
                throws: true) { writer in
            let output = writer.output
            let composeCondition = "Self.self != \(try projection.toTypeName(classDefinition)).self"
            try output.writeLineBlock(header: "try super.init(_compose: \(composeCondition)) {", footer: "}") {
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
    if classDefinition.fullName == "System.Object" {
        return paramTypes.count == 2 // Default composable constructor with Inner and Outer pointers
    }

    for composableAttribute in try classDefinition.getAttributes(ComposableAttribute.self) {
        for composableConstructor in composableAttribute.factory.methods {
            guard try composableConstructor.arity == paramTypes.count else { continue }
            if try composableConstructor.params.map({ try $0.type }) == paramTypes { return true }
        }
    }

    return false
}

fileprivate func writeDefaultActivatableInitializer(
        _ classDefinition: ClassDefinition,
        projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    let documentationComment: SwiftDocumentationComment?
    if let constructor = classDefinition.findConstructor(arity: 0, inherited: false) {
        documentationComment = try projection.getDocumentationComment(constructor)
    } else {
        documentationComment = nil
    }

    try writer.writeInit(documentation: documentationComment, visibility: .public, convenience: true, throws: true) { writer in
        let propertyName = SecondaryInterfaces.getPropertyName(interfaceName: "IActivationFactory")
        let projectionClassName = try projection.toBindingTypeName(classDefinition)
        writer.writeStatement("self.init(_wrapping: \(SupportModules.COM.comReference)(transferringRef: try Self.\(propertyName)"
            + ".activateInstance(binding: \(projectionClassName).self)))")
    }
}

fileprivate func writeActivatableInitializers(
        _ classDefinition: ClassDefinition,
        activationFactory: InterfaceDefinition,
        projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    let propertyName = SecondaryInterfaces.getPropertyName(activationFactory.bind())
    for method in activationFactory.methods {
        let (params, returnParam) = try projection.getParamBindings(method: method, genericTypeArgs: [], abiKind: .activationFactory)
        try writer.writeInit(
                documentation: try projection.getDocumentationComment(abiMember: method, classDefinition: classDefinition),
                visibility: .public,
                convenience: true,
                params: params.map { $0.toSwiftParam() },
                throws: true) { writer in

            // Activation factory interop methods are special-cased to return a COMReference<T> (ABI representation),
            // so we can initialize our instance with it.
            let output = writer.output
            output.write("self.init(_wrapping: ")
            try writeInteropMethodCall(
                name: Projection.toInteropMethodName(method), params: params, returnParam: returnParam,
                thisPointer: .init(name: "Self.\(propertyName)", lazy: true),
                projection: projection, to: writer.output)
            output.write(")")
            output.endLine()
        }
    }
}

fileprivate func writeSupportComposableInitializers(
        defaultInterface: BoundInterface, projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    // public init(_wrapping inner: COMReference<CWinRTComponent.SWRT_IFoo>) {
    //     super.init(_wrapping: inner.cast())
    // }
    let comReferenceType: SwiftType = SupportModules.COM.comReference(to: try projection.toABIType(defaultInterface.asBoundType))
    let param = SwiftParam(label: "_wrapping", name: "inner", consuming: true, type: comReferenceType)
    writer.writeInit(visibility: .public, params: [param]) { writer in
        writer.writeStatement("super.init(_wrapping: inner.cast()) // Transitively casts down to IInspectable")
    }

    // public init<ABIStruct>(_compose: Bool, _factory: ComposableFactory<ABIStruct>) throws {
    writer.writeInit(visibility: .public,
            override: true,
            genericParams: [ "ABIStruct" ],
            params: [ SwiftParam(name: "_compose", type: .bool),
                        SwiftParam(name: "_factory", type: .identifier("ComposableFactory", genericArgs: [ .identifier("ABIStruct") ])) ],
            throws: true) { writer in
        writer.writeStatement("try super.init(_compose: _compose, _factory: _factory)")
    }
}
