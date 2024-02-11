import CodeWriters
import DotNetMetadata
import ProjectionGenerator
import WindowsMetadata

internal enum ThisPointer {
    case name(String)
    case getter(String, static: Bool)
}

internal func writeInterfaceImplementation(
        interfaceOrDelegate: BoundType, static: Bool = false, thisPointer: ThisPointer,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    for property in interfaceOrDelegate.definition.properties {
        try writeInterfacePropertyImplementation(
            property, typeGenericArgs: interfaceOrDelegate.genericArgs,
            static: `static`, thisPointer: thisPointer, projection: projection, to: writer)
    }

    for event in interfaceOrDelegate.definition.events {
        try writeInterfaceEventImplementation(
            event, typeGenericArgs: interfaceOrDelegate.genericArgs,
            static: `static`, thisPointer: thisPointer, projection: projection, to: writer)
    }

    for method in interfaceOrDelegate.definition.methods {
        guard method.isPublic && !(method is Constructor) else { continue }
        // Generate Delegate.Invoke as a regular method
        guard method.nameKind == .regular || interfaceOrDelegate.definition is DelegateDefinition else { continue }
        try writeInterfaceMethodImplementation(
            method, typeGenericArgs: interfaceOrDelegate.genericArgs,
            static: `static`, thisPointer: thisPointer, projection: projection, to: writer)
    }
}

fileprivate func writeInterfacePropertyImplementation(
        _ property: Property, typeGenericArgs: [TypeNode], static: Bool = false, thisPointer: ThisPointer,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    let valueType = try projection.toReturnType(property.type, typeGenericArgs: typeGenericArgs)

    // public [static] var myProperty: MyPropertyType { get throws { .. } }
    if let getter = try property.getter {
        try writer.writeComputedProperty(
                visibility: .public,
                static: `static`,
                name: projection.toMemberName(property),
                type: valueType,
                throws: true) { writer throws in
            try writeInterfaceMethodImplementationBody(
                getter, genericTypeArgs: typeGenericArgs, thisPointer: thisPointer, projection: projection, to: writer)
        }
    }

    // public [static] func myProperty(_ newValue: MyPropertyType) throws { ... }
    if let setter = try property.setter {
        try writer.writeFunc(
                visibility: .public,
                static: `static`,
                name: projection.toMemberName(property),
                params: setter.params.map { try projection.toParameter($0, genericTypeArgs: typeGenericArgs) },
                throws: true) { writer throws in
            try writeInterfaceMethodImplementationBody(
                setter, genericTypeArgs: typeGenericArgs, thisPointer: thisPointer, projection: projection, to: writer)
        }
    }
}

fileprivate func writeInterfaceEventImplementation(
        _ event: Event, typeGenericArgs: [TypeNode], static: Bool = false, thisPointer: ThisPointer,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    let name = projection.toMemberName(event)

    // public [static] func myEvent(adding handler: @escaping MyEventHandler) throws -> EventRegistration { ... }
    if let addAccessor = try event.addAccessor, let addParameter = try addAccessor.params.first {
        try writer.writeFunc(
                visibility: .public,
                static: `static`,
                name: name,
                params: [ try projection.toParameter(label: "adding", addParameter, genericTypeArgs: typeGenericArgs) ],
                throws: true,
                returnType: .chain("WindowsRuntime", "EventRegistration")) { writer throws in
            try writeInterfaceMethodImplementationBody(
                addAccessor, genericTypeArgs: typeGenericArgs, thisPointer: thisPointer,
                context: .eventAdder(removeMethodName: name), projection: projection, to: writer)
        }
    }

    // public [static] func myEvent(removing handler: EventRegistrationToken) throws { ... }
    if let removeAccessor = try event.removeAccessor, let removeParameter = try removeAccessor.params.first {
        try writer.writeFunc(
                visibility: .public,
                static: `static`,
                name: name,
                params: [ try projection.toParameter(label: "removing", removeParameter, genericTypeArgs: typeGenericArgs) ],
                throws: true) { writer throws in
            try writeInterfaceMethodImplementationBody(
                removeAccessor, genericTypeArgs: typeGenericArgs, thisPointer: thisPointer, projection: projection, to: writer)
        }
    }
}

fileprivate func writeInterfaceMethodImplementation(
        _ method: Method, typeGenericArgs: [TypeNode], static: Bool = false, thisPointer: ThisPointer,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    let returnSwiftType: SwiftType? = try method.hasReturnValue
        ? projection.toReturnType(method.returnType, typeGenericArgs: typeGenericArgs)
        : nil
    try writer.writeFunc(
            visibility: .public,
            static: `static`,
            name: projection.toMemberName(method),
            params: method.params.map { try projection.toParameter($0, genericTypeArgs: typeGenericArgs) },
            throws: true,
            returnType: returnSwiftType) { writer throws in
        try writeInterfaceMethodImplementationBody(
            method, genericTypeArgs: typeGenericArgs, thisPointer: thisPointer, projection: projection, to: writer)
    }
}

internal func writeInterfaceMethodImplementationBody(
        _ method: Method, genericTypeArgs: [TypeNode], thisPointer: ThisPointer,
        context: SwiftToABICallContext = .returnableMethod,
        projection: SwiftProjection, to writer: SwiftStatementWriter) throws {
    let thisPointerName = declareThisPointer(thisPointer, to: writer)
    let (params, returnParam) = try projection.getParamProjections(method: method, genericTypeArgs: genericTypeArgs)
    try writeSwiftToABICall(
        params: params,
        returnParam: returnParam,
        abiThisPointer: thisPointerName,
        abiMethodName: try method.findAttribute(OverloadAttribute.self) ?? method.name,
        context: context,
        projection: projection,
        to: writer)
}

internal func declareThisPointer(_ thisPointer: ThisPointer, to writer: SwiftStatementWriter) -> String {
    switch thisPointer {
        case .name(let name): return name
        case let .getter(getter, `static`):
            let staticPrefix = `static` ? "Self." : ""
            writer.writeStatement("let _this = try \(staticPrefix)\(getter)()")
            return "_this"
    }
}

internal enum SwiftToABICallContext {
    case returnableMethod
    case eventAdder(removeMethodName: String)
    case sealedClassInitializer
}

/// Writes a call to an ABI method, converting the Swift parameters to the ABI representation and the return value back to Swift.
internal func writeSwiftToABICall(
        params: [ParamProjection],
        returnParam: ParamProjection?,
        abiThisPointer: String,
        abiMethodName: String,
        context: SwiftToABICallContext,
        projection: SwiftProjection,
        to writer: SwiftStatementWriter) throws {

    var abiArgs = [abiThisPointer]
    func addAbiArg(_ variableName: String, byRef: Bool, array: Bool) {
        let prefix = byRef ? "&" : ""
        if array {
            abiArgs.append("\(prefix)\(variableName).count")
            abiArgs.append("\(prefix)\(variableName).pointer")
        } else {
            abiArgs.append("\(prefix)\(variableName)")
        }
    }

    var needsOutParamsEpilogue = false

    // Prologue: convert arguments from the Swift to the ABI representation
    for param in params {
        let typeProjection = param.typeProjection
        if param.typeProjection.kind == .identity {
            addAbiArg(param.name, byRef: param.passBy != .value, array: false)
            continue
        }

        let declarator: SwiftVariableDeclarator = param.passBy.isReference || typeProjection.kind != .inert ? .var : .let
        if param.passBy.isOutput { needsOutParamsEpilogue = true }

        if param.passBy.isOutput && !param.passBy.isInput {
            writer.writeStatement("\(declarator) \(param.abiProjectionName): \(typeProjection.abiType) = \(typeProjection.abiDefaultValue)")
        }
        else {
            let tryPrefix = typeProjection.kind == .inert ? "" : "try "
            writer.writeStatement("\(declarator) \(param.abiProjectionName) = "
                + "\(tryPrefix)\(typeProjection.projectionType).toABI(\(param.name))")
        }

        if typeProjection.kind != .inert {
            writer.writeStatement("defer { \(typeProjection.projectionType).release(&\(param.abiProjectionName)) }")
        }

        addAbiArg(param.abiProjectionName, byRef: param.passBy.isReference, array: typeProjection.kind == .array)
    }

    func writeOutParamsEpilogue() throws {
        for param in params {
            let typeProjection = param.typeProjection
            if typeProjection.kind != .identity && param.passBy.isOutput {
                if typeProjection.kind == .inert {
                    writer.writeStatement("\(param.name) = \(typeProjection.projectionType).toSwift(\(param.abiProjectionName))")
                }
                else {
                    writer.writeStatement("\(param.name) = \(typeProjection.projectionType).toSwift(consuming: &\(param.abiProjectionName))")
                }
            }
        }
    }

    func writeCall() throws {
        writer.writeStatement("try WinRTError.throwIfFailed(\(abiThisPointer).pointee.lpVtbl.pointee.\(abiMethodName)("
            + "\(abiArgs.joined(separator: ", "))))")
    }

    guard let returnParam else {
        try writeCall()
        if needsOutParamsEpilogue { try writeOutParamsEpilogue() }
        return
    }

    // Value-returning functions
    let returnTypeProjection = returnParam.typeProjection
    writer.writeStatement("var \(returnParam.name): \(returnTypeProjection.abiType) = \(returnTypeProjection.abiDefaultValue)")
    addAbiArg(returnParam.name, byRef: true, array: returnTypeProjection.kind == .array)
    try writeCall()

    if needsOutParamsEpilogue {
        // Don't leak the result if we fail in the out params epilogue
        if returnTypeProjection.kind != .identity && returnTypeProjection.kind != .inert {
            writer.writeStatement("defer { \(returnTypeProjection.projectionType).release(&\(returnParam.name)) }")
        }

        try writeOutParamsEpilogue()
    }

    // Handle the return value
    switch context {
        case .returnableMethod:
            let returnValue: String = switch returnTypeProjection.kind {
                case .identity: returnParam.name
                case .inert: "\(returnTypeProjection.projectionType).toSwift(\(returnParam.name))"
                default: "\(returnTypeProjection.projectionType).toSwift(consuming: &\(returnParam.name))"
            }

            if case .return(nullAsError: true) = returnParam.passBy {
                writer.writeReturnStatement(value: "try COM.NullResult.unwrap(\(returnValue))")
            }
            else {
                writer.writeReturnStatement(value: returnValue)
            }

        case .eventAdder(let removeMethodName):
            // Special case for event add accessors: Wrap the resulting EventRegistrationToken in an EventRegistration object
            writer.writeReturnStatement(value: "WindowsRuntime.EventRegistration("
                + "token: \(returnTypeProjection.projectionType).toSwift(\(returnParam.name)), remover: \(removeMethodName))")

        case .sealedClassInitializer:
            // Sealed class initializers don't return a value but rather forward to the base initializer
            writer.writeStatement("guard let \(returnParam.name) else { throw COM.HResult.Error.noInterface }")
            writer.writeStatement("self.init(transferringRef: \(returnParam.name))")
    }
}