import CodeWriters
import DotNetMetadata
import WindowsMetadata

extension SwiftAssemblyModuleFileWriter {
    internal enum ThisPointer {
        case name(String)
        case getter(String, static: Bool)
    }

    internal func writeProjectionMembers(
            interfaceOrDelegate: BoundType, static: Bool = false, thisPointer: ThisPointer,
            to writer: SwiftTypeDefinitionWriter) throws {
        for property in interfaceOrDelegate.definition.properties {
            try writeProjectionProperty(
                property, typeGenericArgs: interfaceOrDelegate.genericArgs,
                static: `static`, thisPointer: thisPointer, to: writer)
        }

        for event in interfaceOrDelegate.definition.events {
            try writeProjectionEvent(
                event, typeGenericArgs: interfaceOrDelegate.genericArgs,
                static: `static`, thisPointer: thisPointer, to: writer)
        }

        for method in interfaceOrDelegate.definition.methods {
            guard method.isPublic && !(method is Constructor) else { continue }
            // Generate Delegate.Invoke as a regular method
            guard method.nameKind == .regular || interfaceOrDelegate.definition is DelegateDefinition else { continue }
            try writeProjectionMethod(
                method, typeGenericArgs: interfaceOrDelegate.genericArgs,
                static: `static`, thisPointer: thisPointer, to: writer)
        }
    }

    fileprivate func writeProjectionProperty(
            _ property: Property, typeGenericArgs: [TypeNode],
            static: Bool = false, thisPointer: ThisPointer,
            to writer: SwiftTypeDefinitionWriter) throws {
        let valueType = try projection.toType(
            property.type.bindGenericParams(typeArgs: typeGenericArgs))

        // public [static] var myProperty: MyPropertyType { get throws { .. } }
        if let getter = try property.getter {
            try writer.writeComputedProperty(
                    visibility: .public,
                    static: `static`,
                    name: projection.toMemberName(property),
                    type: valueType,
                    throws: true) { writer throws in
                try writeProjectionMethodBody(
                    getter, genericTypeArgs: typeGenericArgs,
                    thisPointer: thisPointer, to: writer)
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
                try writeProjectionMethodBody(
                    setter , genericTypeArgs: typeGenericArgs,
                    thisPointer: thisPointer, to: writer)
            }
        }
    }

    fileprivate func writeProjectionEvent(
            _ event: Event, typeGenericArgs: [TypeNode],
            static: Bool = false, thisPointer: ThisPointer,
            to writer: SwiftTypeDefinitionWriter) throws {
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
                try writeProjectionMethodBody(
                    addAccessor, genericTypeArgs: typeGenericArgs,
                    thisPointer: thisPointer, eventRemoveMethodName: name, to: writer)
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
                try writeProjectionMethodBody(
                    removeAccessor, genericTypeArgs: typeGenericArgs,
                    thisPointer: thisPointer, to: writer)
            }
        }
    }

    fileprivate func writeProjectionMethod(
            _ method: Method, typeGenericArgs: [TypeNode],
            static: Bool = false, thisPointer: ThisPointer,
            to writer: SwiftTypeDefinitionWriter) throws {
        let returnSwiftType: SwiftType? = try method.hasReturnValue
            ? projection.toType(method.returnType.bindGenericParams(typeArgs: typeGenericArgs))
            : nil
        try writer.writeFunc(
                visibility: .public,
                static: `static`,
                name: projection.toMemberName(method),
                params: method.params.map { try projection.toParameter($0, genericTypeArgs: typeGenericArgs) },
                throws: true,
                returnType: returnSwiftType) { writer throws in
            try writeProjectionMethodBody(
                method, genericTypeArgs: typeGenericArgs,
                thisPointer: thisPointer, to: writer)
        }
    }


    internal func writeProjectionMethodBody(
            _ method: Method, genericTypeArgs: [TypeNode], thisPointer: ThisPointer,
            eventRemoveMethodName: String? = nil,
            to writer: SwiftStatementWriter) throws {
        let (params, returnParam) = try projection.getParamProjections(method: method, genericTypeArgs: genericTypeArgs)
        try writeProjectionMethodBody(
            thisPointer: thisPointer,
            params: params,
            returnParam: returnParam,
            abiName: try method.findAttribute(OverloadAttribute.self) ?? method.name,
            eventRemoveMethodName: eventRemoveMethodName,
            to: writer)
    }

    internal func writeProjectionMethodBody(
            thisPointer: ThisPointer,
            params: [ParamProjection],
            returnParam: ParamProjection?,
            abiName: String,
            eventRemoveMethodName: String? = nil,
            isInitializer: Bool = false,
            to writer: SwiftStatementWriter) throws {

        let thisName: String
        switch thisPointer {
            case .name(let name): thisName = name
            case let .getter(getter, `static`):
                thisName = "_this"
                let staticPrefix = `static` ? "Self." : ""
                writer.writeStatement("let _this = try \(staticPrefix)\(getter)()")
        }

        var abiArgs = [thisName]
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
            writer.writeStatement("try WinRTError.throwIfFailed(\(thisName).pointee.lpVtbl.pointee.\(abiName)("
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
        if let eventRemoveMethodName {
            // Special case for event add accessors: Wrap the resulting EventRegistrationToken in an EventRegistration object
            writer.writeReturnStatement(value: "WindowsRuntime.EventRegistration("
                + "token: \(returnTypeProjection.projectionType).toSwift(\(returnParam.name)), remover: \(eventRemoveMethodName))")
        }
        else if isInitializer {
            // Initializers don't return a value but rather forward to the base initializer
            writer.writeStatement("guard let \(returnParam.name) else { throw COM.HResult.Error.noInterface }")
            writer.writeStatement("self.init(transferringRef: \(returnParam.name))")
        }
        else {
            switch returnTypeProjection.kind {
                case .identity:
                    writer.writeReturnStatement(value: returnParam.name)
                case .inert:
                    writer.writeReturnStatement(value: "\(returnTypeProjection.projectionType).toSwift(\(returnParam.name))")
                default:
                    writer.writeReturnStatement(value: "\(returnTypeProjection.projectionType).toSwift(consuming: &\(returnParam.name))")
            }
        }
    }
}