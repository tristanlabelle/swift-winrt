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

            let declarator: SwiftVariableDeclarator
            let variableName: String
            if param.isByRef {
                declarator = .var
                variableName = "_\(paramName)" // Preserve the original name so we can assign back
                abiArgs.append("&\(variableName)")
            }
            else {
                declarator = .let
                variableName = paramName
                abiArgs.append(variableName)
            }

            if !abi.identity {
                if abi.inert {
                    writer.writeStatement("\(declarator) \(variableName) = \(abi.projectionType).toABI(\(paramName))")
                }
                else {
                    writer.writeStatement("\(declarator) \(variableName) = try \(abi.projectionType).toABI(\(paramName))")
                    writer.writeStatement("defer { \(abi.projectionType).release(\(variableName)) }")
                }
            }
        }

        func writeCall() throws {
            let abiMethodName = try method.findAttribute(OverloadAttribute.self) ?? method.name
            writer.writeStatement("try HResult.throwIfFailed(\(thisName).pointee.lpVtbl.pointee.\(abiMethodName)(\(abiArgs.joined(separator: ", "))))")
        }

        // Epilogue: convert the return value and out params from the ABI to the Swift representation
        // TODO: Convert out values back to Swift
        if try !method.hasReturnValue {
            try writeCall()
            return
        }

        let returnTypeProjection = try projection.getTypeProjection(
            method.returnType.bindGenericParams(typeArgs: genericTypeArgs))
        guard let returnAbi = returnTypeProjection.abi else {
            writer.writeNotImplemented()
            return
        }

        writer.writeStatement("var _result: \(returnAbi.valueType) = \(returnAbi.defaultValue)")
        abiArgs.append("&_result")
        try writeCall()

        if returnAbi.identity {
            writer.writeStatement("return _result")
        }
        else {
            writer.writeStatement("return \(returnAbi.projectionType).toSwift(consuming: _result)")
        }
    }
}