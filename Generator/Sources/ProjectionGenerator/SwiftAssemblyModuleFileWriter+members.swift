import CodeWriters
import DotNetMetadata
import WindowsMetadata

extension SwiftAssemblyModuleFileWriter {
    internal enum ThisPointer {
        case name(String)
        case getter(String)
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
                    parameters: setter.params.map { try projection.toParameter($0, genericTypeArgs: typeGenericArgs) },
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
                    parameters: [ try projection.toParameter(label: "adding", addParameter, genericTypeArgs: typeGenericArgs) ],
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
                    parameters: [ try projection.toParameter(label: "removing", removeParameter, genericTypeArgs: typeGenericArgs) ],
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
                parameters: method.params.map { try projection.toParameter($0, genericTypeArgs: typeGenericArgs) },
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

        let thisName: String
        switch thisPointer {
            case .name(let name): thisName = name
            case .getter(let getter):
                thisName = "_this"
                writer.writeStatement("let _this = try \(getter)()")
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
        for param in try method.params {
            guard let paramName = param.name else {
                writer.writeNotImplemented()
                return
            }

            let typeProjection = try projection.getTypeProjection(param.type.bindGenericParams(typeArgs: genericTypeArgs))
            guard let abi = typeProjection.abi else {
                writer.writeNotImplemented()
                return
            }

            if abi.kind == .identity {
                addAbiArg(paramName, byRef: param.isByRef, array: false)
                continue
            }

            let declarator: SwiftVariableDeclarator = param.isByRef || abi.kind != .inert ? .var : .let
            let variableName: String = param.isByRef && param.isOut ? "_\(paramName)" : paramName
            if param.isByRef && param.isOut { needsOutParamsEpilogue = true }

            if param.isOut && !param.isIn {
                writer.writeStatement("\(declarator) \(variableName): \(abi.type) = \(abi.defaultValue)")
            }
            else {
                let tryPrefix = abi.kind == .inert ? "" : "try "
                writer.writeStatement("\(declarator) \(variableName) = \(tryPrefix)\(abi.projectionType).toABI(\(paramName))")
            }

            if abi.kind != .inert {
                writer.writeStatement("defer { \(abi.projectionType).release(&\(variableName)) }")
            }

            addAbiArg(variableName, byRef: param.isByRef, array: abi.kind == .array)
        }

        func writeOutParamsEpilogue() throws {
            for param in try method.params {
                guard let paramName = param.name else {
                    writer.writeNotImplemented()
                    return
                }

                let typeProjection = try projection.getTypeProjection(param.type.bindGenericParams(typeArgs: genericTypeArgs))
                guard let abi = typeProjection.abi else {
                    writer.writeNotImplemented()
                    return
                }

                if abi.kind != .identity && param.isOut {
                    if abi.kind == .inert {
                        writer.writeStatement("\(paramName) = \(abi.projectionType).toSwift(_\(paramName))")
                    }
                    else {
                        writer.writeStatement("\(paramName) = \(abi.projectionType).toSwift(consuming: &_\(paramName))")
                    }
                }
            }
        }

        func writeCall() throws {
            let abiMethodName = try method.findAttribute(OverloadAttribute.self) ?? method.name
            writer.writeStatement("try WinRTError.throwIfFailed(\(thisName).pointee.lpVtbl.pointee.\(abiMethodName)(\(abiArgs.joined(separator: ", "))))")
        }

        if try !method.hasReturnValue {
            try writeCall()
            if needsOutParamsEpilogue { try writeOutParamsEpilogue() }
            return
        }

        // Value-returning functions
        let returnTypeProjection = try projection.getTypeProjection(
            method.returnType.bindGenericParams(typeArgs: genericTypeArgs))
        guard let returnAbi = returnTypeProjection.abi else {
            writer.writeNotImplemented()
            return
        }

        writer.writeStatement("var _result: \(returnAbi.type) = \(returnAbi.defaultValue)")
        addAbiArg("_result", byRef: true, array: returnAbi.kind == .array)
        try writeCall()

        if needsOutParamsEpilogue {
            // Don't leak the result if we fail in the out params epilogue
            if returnAbi.kind != .identity && returnAbi.kind != .inert {
                writer.writeStatement("defer { \(returnAbi.projectionType).release(&_result) }")
            }

            try writeOutParamsEpilogue()
        }

        if let eventRemoveMethodName {
            // Special case for event add accessors: Wrap the resulting EventRegistrationToken in an EventRegistration object
            writer.writeReturnStatement(value: "WindowsRuntime.EventRegistration(token: \(returnAbi.projectionType).toSwift(_result), remover: \(eventRemoveMethodName))")
            return
        }

        switch returnAbi.kind {
            case .identity: writer.writeReturnStatement(value: "_result")
            case .inert: writer.writeReturnStatement(value: "\(returnAbi.projectionType).toSwift(_result)")
            default: writer.writeReturnStatement(value: "\(returnAbi.projectionType).toSwift(consuming: &_result)")
        }
    }
}