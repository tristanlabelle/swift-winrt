import CodeWriters
import DotNetMetadata
import WindowsMetadata

extension SwiftAssemblyModuleFileWriter {
    internal enum ThisPointer {
        case name(String)
        case getter(String)
    }

    internal func writeMemberImplementations(
            interfaceOrDelegate: BoundType, static: Bool = false, thisPointer: ThisPointer,
            to writer: SwiftTypeDefinitionWriter) throws {
        for property in interfaceOrDelegate.definition.properties {
            let swiftPropertyType = try projection.toType(
                property.type.bindGenericParams(typeArgs: interfaceOrDelegate.genericArgs))

            if let getter = try property.getter, getter.isPublic {
                try writer.writeComputedProperty(
                    visibility: .public,
                    static: `static`,
                    name: projection.toMemberName(property),
                    type: swiftPropertyType,
                    throws: true) { writer throws in

                    try writeMethodImplementation(getter, genericTypeArgs: interfaceOrDelegate.genericArgs,
                        thisPointer: thisPointer, to: &writer)
                }
            }

            if let setter = try property.setter, setter.isPublic {
                try writer.writeFunc(
                    visibility: .public,
                    static: `static`,
                    name: projection.toMemberName(property),
                    parameters: [SwiftParameter(label: "_", name: "newValue", type: swiftPropertyType)],
                    throws: true) { writer throws in

                    try writeMethodImplementation(setter , genericTypeArgs: interfaceOrDelegate.genericArgs,
                        thisPointer: thisPointer, to: &writer)
                }
            }
        }

        for method in interfaceOrDelegate.definition.methods {
            guard method.isPublic && !(method is Constructor) else { continue }
            // Generate Delegate.Invoke as a regular method
            guard method.nameKind == .regular || interfaceOrDelegate.definition is DelegateDefinition else { continue }

            let returnSwiftType: SwiftType? = try method.hasReturnValue
                ? projection.toType(method.returnType.bindGenericParams(typeArgs: interfaceOrDelegate.genericArgs))
                : nil
            try writer.writeFunc(
                visibility: .public,
                static: `static`,
                name: projection.toMemberName(method),
                parameters: method.params.map { try projection.toParameter($0, genericTypeArgs: interfaceOrDelegate.genericArgs) },
                throws: true,
                returnType: returnSwiftType) { writer throws in

                try writeMethodImplementation(method, genericTypeArgs: interfaceOrDelegate.genericArgs,
                    thisPointer: thisPointer, to: &writer)
            }
        }
    }

    internal func writeMethodImplementation(
            _ method: Method, genericTypeArgs: [TypeNode], thisPointer: ThisPointer,
            to writer: inout SwiftStatementWriter) throws {

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
                abiArgs.append("\(prefix)\(variableName).elements")
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
                    writer.writeStatement("\(paramName) = \(abi.projectionType).toSwift(consuming: &_\(paramName))")
                    if abi.kind != .inert {
                        // Prevent the defer block from double-releasing the value
                        writer.writeStatement("_\(paramName) = \(abi.defaultValue)")
                    }
                }
            }
        }

        func writeCall() throws {
            let abiMethodName = try method.findAttribute(OverloadAttribute.self) ?? method.name
            writer.writeStatement("try HResult.throwIfFailed(\(thisName).pointee.lpVtbl.pointee.\(abiMethodName)(\(abiArgs.joined(separator: ", "))))")
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

        switch returnAbi.kind {
            case .identity: writer.writeStatement("return _result")
            case .inert: writer.writeStatement("return \(returnAbi.projectionType).toSwift(_result)")
            default: writer.writeStatement("return \(returnAbi.projectionType).toSwift(consuming: &_result)")
        }
    }
}