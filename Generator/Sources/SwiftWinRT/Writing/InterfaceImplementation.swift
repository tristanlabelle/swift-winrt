import CodeWriters
import DotNetMetadata
import ProjectionModel
import WindowsMetadata

internal struct ThisPointer {
    public let name: String
    public let lazy: Bool

    public init(name: String, lazy: Bool = false) {
        self.name = name
        self.lazy = lazy
    }
}

internal func writeInterfaceImplementation(
        abiType: BoundType, classDefinition: ClassDefinition? = nil, documentation: Bool = true,
        overridable: Bool = false, static: Bool = false, thisPointer: ThisPointer,
        projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    for method in abiType.definition.methods {
        guard method.isPublic && !(method is Constructor) else { continue }
        // Generate Delegate.Invoke as a regular method
        guard method.nameKind == .regular || abiType.definition is DelegateDefinition else { continue }
        try writeInterfaceMethodImplementation(
            method, typeGenericArgs: abiType.genericArgs, classDefinition: classDefinition,
            documentation: documentation, overridable: overridable, static: `static`,
            thisPointer: thisPointer, projection: projection, to: writer)
    }

    for event in abiType.definition.events {
        try writeInterfaceEventImplementation(
            event, typeGenericArgs: abiType.genericArgs, classDefinition: classDefinition,
            documentation: documentation, overridable: overridable, static: `static`,
            thisPointer: thisPointer, projection: projection, to: writer)
    }

    for property in abiType.definition.properties {
        try writeInterfacePropertyImplementation(
            property, typeGenericArgs: abiType.genericArgs, classDefinition: classDefinition,
            documentation: documentation, overridable: overridable, static: `static`,
            thisPointer: thisPointer, projection: projection, to: writer)
    }
}

fileprivate func writeInterfacePropertyImplementation(
        _ property: Property, typeGenericArgs: [TypeNode], classDefinition: ClassDefinition?,
        documentation: Bool, overridable: Bool, static: Bool, thisPointer: ThisPointer,
        projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    if try property.definingType.hasAttribute(ExclusiveToAttribute.self) {
        // The property is exclusive to this class so it doesn't come
        // from an interface that would an extension property.
        // public static var myProperty: MyPropertyType { ... }
        try writeNonthrowingPropertyImplementation(
            property: property, static: `static`, projection: projection, to: writer)
    }

    // public [static] func _myProperty() throws -> MyPropertyType { ... }
    if let getter = try property.getter, try getter.hasReturnValue {
        let returnParamBinding = try projection.getParamBinding(getter.returnParam, genericTypeArgs: typeGenericArgs)
        try writer.writeFunc(
                documentation: documentation ? projection.getDocumentationComment(abiMember: property, classDefinition: classDefinition) : nil,
                visibility: overridable ? .open : .public,
                static: `static`,
                name: Projection.toMemberName(getter),
                throws: true,
                returnType: returnParamBinding.swiftType) { writer throws in
            try writeInteropMethodCall(
                name: Projection.toInteropMethodName(getter), params: [], returnParam: returnParamBinding,
                thisPointer: thisPointer, projection: projection, to: writer.output)
        }
    }

    // public [static] func myProperty(_ newValue: MyPropertyType) throws { ... }
    if let setter = try property.setter {
        guard let newValueParam = try setter.params.first else { fatalError() }
        let newValueParamBinding = try projection.getParamBinding(newValueParam, genericTypeArgs: typeGenericArgs)
        try writer.writeFunc(
                documentation: documentation ? projection.getDocumentationComment(abiMember: property, classDefinition: classDefinition) : nil,
                visibility: .public,
                static: `static`,
                name: Projection.toMemberName(setter),
                params: [ newValueParamBinding.toSwiftParam() ],
                throws: true) { writer throws in
            try writeInteropMethodCall(
                name: Projection.toInteropMethodName(setter),
                params: [ newValueParamBinding ], returnParam: nil,
                thisPointer: thisPointer, projection: projection, to: writer.output)
        }
    }
}

fileprivate func writeInterfaceEventImplementation(
        _ event: Event, typeGenericArgs: [TypeNode], classDefinition: ClassDefinition?,
        documentation: Bool, overridable: Bool, static: Bool, thisPointer: ThisPointer,
        projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    let name = Projection.toMemberName(event)

    // public [static] func myEvent(adding handler: @escaping MyEventHandler) throws -> EventRegistration { ... }
    if let addAccessor = try event.addAccessor, let handlerParameter = try addAccessor.params.first {
        let handlerParamBinding = try projection.getParamBinding(handlerParameter, genericTypeArgs: typeGenericArgs)
        let eventRegistrationType = SupportModules.WinRT.eventRegistration
        try writer.writeFunc(
                documentation: documentation ? projection.getDocumentationComment(abiMember: event, classDefinition: classDefinition) : nil,
                visibility: overridable ? .open : .public, static: `static`, name: name,
                params: [ handlerParamBinding.toSwiftParam(label: "adding") ], throws: true,
                returnType: eventRegistrationType) { writer throws in
            // Convert the return token into an EventRegistration type for ease of unregistering
            let output = writer.output
            output.write("let _token = ")
            try writeInteropMethodCall(
                name: Projection.toInteropMethodName(addAccessor),
                params: [ handlerParamBinding ], returnParam: nil,
                thisPointer: thisPointer, projection: projection, to: output)
            output.endLine()

            writer.writeReturnStatement(value: "\(eventRegistrationType)(source: self, token: _token, remover: { this, token in try (this as! Self).\(name)(removing: token) })")
        }
    }

    // public [static] func myEvent(removing token: EventRegistrationToken) throws { ... }
    if let removeAccessor = try event.removeAccessor, let tokenParameter = try removeAccessor.params.first {
        let tokenParamBinding = try projection.getParamBinding(tokenParameter, genericTypeArgs: typeGenericArgs)
        try writer.writeFunc(
                visibility: overridable ? .open : .public,
                static: `static`,
                name: name,
                params: [ tokenParamBinding.toSwiftParam(label: "removing") ],
                throws: true) { writer throws in
            try writeInteropMethodCall(
                name: Projection.toInteropMethodName(removeAccessor),
                params: [ tokenParamBinding ], returnParam: nil,
                thisPointer: thisPointer, projection: projection, to: writer.output)
        }
    }
}

fileprivate func writeInterfaceMethodImplementation(
        _ method: Method, typeGenericArgs: [TypeNode], classDefinition: ClassDefinition?,
        documentation: Bool, overridable: Bool, static: Bool, thisPointer: ThisPointer,
        projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    let (params, returnParam) = try projection.getParamBindings(method: method, genericTypeArgs: typeGenericArgs)
    try writer.writeFunc(
            documentation: documentation ? projection.getDocumentationComment(abiMember: method, classDefinition: classDefinition) : nil,
            attributes: Projection.getSwiftAttributes(method),
            visibility: overridable ? .open : .public,
            static: `static`,
            name: Projection.toMemberName(method),
            params: params.map { $0.toSwiftParam() },
            throws: true,
            returnType: returnParam?.swiftType) { writer throws in
        try writeInteropMethodCall(
            name: Projection.toInteropMethodName(method),
            params: params, returnParam: returnParam,
            thisPointer: thisPointer, projection: projection, to: writer.output)
    }
}

internal func writeInteropMethodCall(
        name: String, params: [ParamProjection], returnParam: ParamProjection?, thisPointer: ThisPointer,
        projection: Projection, to output: LineBasedTextOutputStream) throws {

    let nullReturnAsError = {
        if let returnParam, case .return(nullAsError: true) = returnParam.passBy { return true }
        return false
    }()

    output.write("try ")
    if nullReturnAsError { output.write("\(SupportModules.COM.nullResult).unwrap(") }
    output.write("\(thisPointer.name).\(name)(")
    for (i, param) in params.enumerated() {
        if i > 0 { output.write(", ") }
        if case .reference(in: _, out: true, optional: _) = param.passBy { output.write("&") }
        output.write(param.name)
    }
    if nullReturnAsError { output.write(")") }
    output.write(")")
}
