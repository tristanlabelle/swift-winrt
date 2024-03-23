import CodeWriters
import DotNetMetadata
import ProjectionModel
import WindowsMetadata

internal func writeVirtualTableProperty(
        visibility: SwiftVisibility = .private, name: String, abiType: BoundType, swiftType: BoundType,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    try writer.writeStoredProperty(
        visibility: visibility, static: true, declarator: .var, name: name,
        initializer: { output in try writeVirtualTable(abiType: abiType, swiftType: swiftType, projection: projection, to: output) })
}

fileprivate func writeVirtualTable(
        abiType: BoundType, swiftType: BoundType,
        projection: SwiftProjection, to output: IndentedTextOutputStream) throws {
    let vtableStructType: SwiftType = try projection.toABIVirtualTableType(abiType)
    try output.writeIndentedBlock(header: "\(vtableStructType)(", footer: ")") {
        // IUnknown methods
        output.writeFullLine("QueryInterface: { COMExportedInterface.QueryInterface($0, $1, $2) },")
        output.writeFullLine("AddRef: { COMExportedInterface.AddRef($0) },")
        output.write("Release: { COMExportedInterface.Release($0) }")

        // IInspectable methods (except for delegates)
        if abiType.definition is InterfaceDefinition {
            output.write(",", endLine: true)
            output.writeFullLine("GetIids: { WinRTExportedInterface.GetIids($0, $1, $2) },")
            output.writeFullLine("GetRuntimeClassName: { WinRTExportedInterface.GetRuntimeClassName($0, $1) },")
            output.write("GetTrustLevel: { WinRTExportedInterface.GetTrustLevel($0, $1) }")
        }

        // Custom interface/delegate methods
        for method in abiType.definition.methods {
            // Delegates have a constructor in the metadata, ignore it
            if method is Constructor { continue }

            output.write(",", endLine: true)

            output.write(try method.findAttribute(OverloadAttribute.self)?.methodName ?? method.name)
            output.write(": ")
            output.write("{ this")

            let (params, returnParam) = try projection.getParamProjections(method: method, genericTypeArgs: abiType.genericArgs)
            for abiParamName in getABIParamNames(params, returnParam: returnParam) {
                output.write(", ")
                output.write(abiParamName)
            }

            output.write(" in ")
            if swiftType == abiType {
                output.write("_implement(this)")
            }
            else {
                let implementationType = try projection.toTypeName(swiftType.definition)
                output.write("\(SupportModules.COM.implementABIMethodFunc)(this, type: \(implementationType).self)")
            }

            try output.writeIndentedBlock(header: " { this in") {
                try writeVirtualTableFunc(
                    params: params, returnParam: returnParam,
                    swiftMemberName: SwiftProjection.toMemberName(method),
                    methodKind: WinRTMethodKind(from: method),
                    to: output)
            }
            output.write("} }") // We might append a comma, so don't end the line
        }
    }
}

fileprivate func getABIParamNames(_ params: [ParamProjection], returnParam: ParamProjection?) -> [String] {
    var abiParamNames = [String]()
    for param in params {
        if param.isArray { abiParamNames.append(param.arrayLengthName) }
        abiParamNames.append(param.name)
    }
    if let returnParam {
        if returnParam.isArray { abiParamNames.append(returnParam.arrayLengthName) }
        abiParamNames.append(returnParam.name)
    }
    return abiParamNames
}

fileprivate func writeVirtualTableFunc(
        params: [ParamProjection], returnParam: ParamProjection?,
        swiftMemberName: String, methodKind: WinRTMethodKind, to output: IndentedTextOutputStream) throws {
    // Ensure non-optional by reference params are non-null pointers
    for param in params {
        guard case .reference(in: _, out: _, optional: false) = param.passBy else { continue }
        output.writeFullLine("guard let \(param.name) else { throw COM.HResult.Error.pointer }")
    }
    if let returnParam {
        output.writeFullLine("guard let \(returnParam.name) else { throw COM.HResult.Error.pointer }")
    }

    // Declare the Swift representation of params
    var epilogueOutParamWithCleanupCount = 0
    for param in params {
        guard param.typeProjection.kind != .identity else { continue }
        if param.passBy.isOutput, param.typeProjection.kind != .inert {
            epilogueOutParamWithCleanupCount += 1
        }
        try writePrologueForParam(param, to: output)
    }

    // Set up the return value
    if let returnParam {
        if returnParam.typeProjection.kind == .identity {
            output.write("\(returnParam.name).pointee = ")
        }
        else {
            if returnParam.typeProjection.kind != .inert {
                epilogueOutParamWithCleanupCount += 1
            }
            output.write("let \(returnParam.swiftProjectionName) = ")
        }

        if case .return(nullAsError: true) = returnParam.passBy {
            output.write("try \(SupportModules.COM.nullResult).`catch`(")
        }
    }

    // Call the Swift implementation
    output.write("try ")
    output.write(methodKind == .delegateInvoke
        ? "this" : "this.\(swiftMemberName)")
    output.write("(")
    if methodKind == .eventAdder || methodKind == .eventRemover {
        assert(params.count == 1)
        output.write(methodKind == .eventAdder ? "adding: " : "removing: ")
    }
    for (index, param) in params.enumerated() {
        if index > 0 { output.write(", ") }
        if param.passBy != .value { output.write("&") }
        if param.typeProjection.kind == .identity {
            output.write(param.name)
            if param.passBy != .value { output.write(".pointee") }
        } else {
            output.write(param.swiftProjectionName)
        }
    }
    output.write(")")
    if methodKind == .eventAdder { output.write(".token") }

    if let returnParam, case .return(nullAsError: true) = returnParam.passBy {
        output.write(")") // NullResult.`catch`
    }
    output.endLine()

    // Convert out params to the ABI representation
    let epilogueRequiresCleanup = epilogueOutParamWithCleanupCount > 1
    if epilogueRequiresCleanup { output.writeFullLine("var _success = false") }

    for param in params {
        guard param.passBy.isOutput, param.typeProjection.kind != .identity else { continue }
        try writeEpilogueForOutParam(param, skipCleanup: !epilogueRequiresCleanup, to: output)
    }

    if let returnParam, returnParam.typeProjection.kind != .identity {
        try writeEpilogueForOutParam(returnParam, skipCleanup: !epilogueRequiresCleanup, to: output)
    }

    if epilogueRequiresCleanup { output.writeFullLine("_success = true") }
}

fileprivate func writeVirtualTableFuncImplementation(name: String, paramNames: [String], to output: IndentedTextOutputStream, body: () throws -> Void) rethrows {
    output.write(name)
    output.write(": ")
    output.write("{ this")
    for paramName in paramNames {
        output.write(", \(paramName)")
    }
    try output.writeIndentedBlock(header: " in _implement(this) { this in", body: body)
    output.write("} }")
}

fileprivate func writePrologueForParam(_ param: ParamProjection, to output: IndentedTextOutputStream) throws {
    if param.passBy.isInput {
        let declarator: SwiftVariableDeclarator = param.passBy.isOutput ? .var : .let
        output.write("\(declarator) \(param.swiftProjectionName) = \(param.projectionType).toSwift")
        switch param.typeProjection.kind {
            case .identity: fatalError("Case should have been ignored earlier.")
            case .inert, .allocating:
                output.write("(\(param.name))")
            case .array:
                output.write("(pointer: \(param.name), count: \(param.arrayLengthName))")
        }
    } else {
        output.write("var \(param.swiftProjectionName): \(param.typeProjection.swiftType)"
            + " = \(param.typeProjection.swiftDefaultValue)")
    }
    output.endLine()
}

fileprivate func writeEpilogueForOutParam(_ param: ParamProjection, skipCleanup: Bool, to output: IndentedTextOutputStream) throws {
    precondition(param.passBy.isOutput)

    if param.typeProjection.kind == .array {
        output.writeFullLine(#"fatalError("Not implemented: out arrays")"#)
    }
    else {
        let isOptional: Bool
        if case .reference(in: _, out: _, optional: true) = param.passBy {
            isOptional = true
        } else {
            isOptional = false
        }

        if isOptional { output.write("if let \(param.name) { ") }

        output.write("\(param.name).pointee = ")
        if param.typeProjection.kind == .identity {
            output.write(param.swiftProjectionName)
        } else {
            if param.typeProjection.kind == .allocating { output.write ("try ") }
            output.write("\(param.projectionType).toABI(\(param.swiftProjectionName))")
        }

        if isOptional { output.write(" }") }
        
        output.endLine()

        if param.typeProjection.kind == .allocating, !skipCleanup {
            output.write("defer { ")
            output.write("if !_success, let \(param.name) { ")
            output.write("\(param.projectionType).release(&\(param.name).pointee)")
            output.write(" }")
            output.write(" }", endLine: true)
        }
    }
}