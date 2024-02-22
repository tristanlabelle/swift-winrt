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
        interfaceOrDelegate: BoundType, overridable: Bool = false, static: Bool = false, thisPointer: ThisPointer,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    for property in interfaceOrDelegate.definition.properties {
        try writeInterfacePropertyImplementation(
            property, typeGenericArgs: interfaceOrDelegate.genericArgs,
            overridable: overridable, static: `static`, thisPointer: thisPointer,
            projection: projection, to: writer)
    }

    for event in interfaceOrDelegate.definition.events {
        try writeInterfaceEventImplementation(
            event, typeGenericArgs: interfaceOrDelegate.genericArgs,
            overridable: overridable, static: `static`, thisPointer: thisPointer,
            projection: projection, to: writer)
    }

    for method in interfaceOrDelegate.definition.methods {
        guard method.isPublic && !(method is Constructor) else { continue }
        // Generate Delegate.Invoke as a regular method
        guard method.nameKind == .regular || interfaceOrDelegate.definition is DelegateDefinition else { continue }
        try writeInterfaceMethodImplementation(
            method, typeGenericArgs: interfaceOrDelegate.genericArgs,
            overridable: overridable, static: `static`, thisPointer: thisPointer,
            projection: projection, to: writer)
    }
}

fileprivate func writeInterfacePropertyImplementation(
        _ property: Property, typeGenericArgs: [TypeNode], overridable: Bool, static: Bool, thisPointer: ThisPointer,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    // public [static] var myProperty: MyPropertyType { get throws { .. } }
    if let getter = try property.getter, try getter.hasReturnValue {
        let returnParamProjection = try projection.getParamProjection(getter.returnParam, genericTypeArgs: typeGenericArgs)
        try writer.writeComputedProperty(
                documentation: try projection.getDocumentationComment(property),
                visibility: overridable ? .open : .public,
                static: `static`,
                name: SwiftProjection.toMemberName(property),
                type: returnParamProjection.swiftType,
                throws: true) { writer throws in
            try writeInteropMethodCall(
                name: SwiftProjection.toInteropMethodName(getter), params: [], returnParam: returnParamProjection,
                thisPointer: thisPointer, projection: projection, to: writer.output)
        }
    }

    // public [static] func myProperty(_ newValue: MyPropertyType) throws { ... }
    if let setter = try property.setter {
        guard let newValueParam = try setter.params.first else { fatalError() }
        let newValueParamProjection = try projection.getParamProjection(newValueParam, genericTypeArgs: typeGenericArgs)
        try writer.writeFunc(
                documentation: try projection.getDocumentationComment(property),
                visibility: .public,
                static: `static`,
                name: SwiftProjection.toMemberName(property),
                params: [ newValueParamProjection.toSwiftParam() ],
                throws: true) { writer throws in
            try writeInteropMethodCall(
                name: SwiftProjection.toInteropMethodName(setter),
                params: [ newValueParamProjection ], returnParam: nil,
                thisPointer: thisPointer, projection: projection, to: writer.output)
        }
    }
}

fileprivate func writeInterfaceEventImplementation(
        _ event: Event, typeGenericArgs: [TypeNode], overridable: Bool, static: Bool, thisPointer: ThisPointer,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    let name = SwiftProjection.toMemberName(event)

    // public [static] func myEvent(adding handler: @escaping MyEventHandler) throws -> EventRegistration { ... }
    if let addAccessor = try event.addAccessor, let handlerParameter = try addAccessor.params.first {
        let handlerParamProjection = try projection.getParamProjection(handlerParameter, genericTypeArgs: typeGenericArgs)
        let eventRegistrationType = SupportModule.eventRegistration
        try writer.writeFunc(
                documentation: try projection.getDocumentationComment(event),
                visibility: overridable ? .open : .public, static: `static`, name: name,
                params: [ handlerParamProjection.toSwiftParam(label: "adding") ], throws: true,
                returnType: eventRegistrationType) { writer throws in
            // Convert the return token into an EventRegistration type for ease of unregistering
            let output = writer.output
            output.write("let _token = ")
            try writeInteropMethodCall(
                name: SwiftProjection.toInteropMethodName(addAccessor),
                params: [ handlerParamProjection ], returnParam: nil,
                thisPointer: thisPointer, projection: projection, to: output)
            output.endLine()

            writer.writeReturnStatement(value: "\(eventRegistrationType)(token: _token, remover: \(name))")
        }
    }

    // public [static] func myEvent(removing token: EventRegistrationToken) throws { ... }
    if let removeAccessor = try event.removeAccessor, let tokenParameter = try removeAccessor.params.first {
        let tokenParamProjection = try projection.getParamProjection(tokenParameter, genericTypeArgs: typeGenericArgs)
        try writer.writeFunc(
                documentation: try projection.getDocumentationComment(event),
                visibility: overridable ? .open : .public,
                static: `static`,
                name: name,
                params: [ tokenParamProjection.toSwiftParam(label: "removing") ],
                throws: true) { writer throws in
            try writeInteropMethodCall(
                name: SwiftProjection.toInteropMethodName(removeAccessor),
                params: [ tokenParamProjection ], returnParam: nil,
                thisPointer: thisPointer, projection: projection, to: writer.output)
        }
    }
}

fileprivate func writeInterfaceMethodImplementation(
        _ method: Method, typeGenericArgs: [TypeNode], overridable: Bool, static: Bool, thisPointer: ThisPointer,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    let (params, returnParam) = try projection.getParamProjections(method: method, genericTypeArgs: typeGenericArgs)
    try writer.writeFunc(
            documentation: try projection.getDocumentationComment(method),
            visibility: overridable ? .open : .public,
            static: `static`,
            name: SwiftProjection.toMemberName(method),
            params: params.map { $0.toSwiftParam() },
            throws: true,
            returnType: returnParam?.swiftType) { writer throws in
        try writeInteropMethodCall(
            name: SwiftProjection.toInteropMethodName(method),
            params: params, returnParam: returnParam,
            thisPointer: thisPointer, projection: projection, to: writer.output)
    }
}

internal func writeInteropMethodCall(
        name: String, params: [ParamProjection], returnParam: ParamProjection?, thisPointer: ThisPointer,
        projection: SwiftProjection, to output: IndentedTextOutputStream) throws {

    let nullReturnAsError = {
        if let returnParam, case .return(nullAsError: true) = returnParam.passBy { return true }
        return false
    }()

    output.write("try ")
    if nullReturnAsError { output.write("\(SupportModule.nullResult).unwrap(") }
    output.write("\(thisPointer.name).\(name)(")
    for (i, param) in params.enumerated() {
        if i > 0 { output.write(", ") }
        if case .reference(in: _, out: true, optional: _) = param.passBy { output.write("&") }
        output.write(param.name)
    }
    if nullReturnAsError { output.write(")") }
    output.write(")")
}
