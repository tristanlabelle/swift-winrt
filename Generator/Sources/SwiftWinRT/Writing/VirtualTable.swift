import CodeWriters
import DotNetMetadata
import ProjectionGenerator
import WindowsMetadata

func writeVirtualTable(interfaceOrDelegate: BoundType, projection: SwiftProjection, to output: IndentedTextOutputStream) throws {
    try output.writeIndentedBlock(header: "COMVirtualTable(", footer: ")") {
        // IUnknown methods
        output.writeFullLine("QueryInterface: { COMExportedInterface.QueryInterface($0, $1, $2) },")
        output.writeFullLine("AddRef: { COMExportedInterface.AddRef($0) },")
        output.write("Release: { COMExportedInterface.Release($0) }")

        // IInspectable methods (except for delegates)
        if interfaceOrDelegate.definition is InterfaceDefinition {
            output.write(",", endLine: true)
            output.writeFullLine("GetIids: { WinRTExportedInterface.GetIids($0, $1, $2) },")
            output.writeFullLine("GetRuntimeClassName: { WinRTExportedInterface.GetRuntimeClassName($0, $1) },")
            output.write("GetTrustLevel: { WinRTExportedInterface.GetTrustLevel($0, $1) }")
        }

        // Custom interface/delegate methods
        for method in interfaceOrDelegate.definition.methods {
            // Delegates have a constructor in the metadata, ignore it
            if method is Constructor { continue }
            output.write(",", endLine: true)
            try writeVirtualTableFunc(method, genericTypeArgs: interfaceOrDelegate.genericArgs, projection: projection, to: output)
        }
    }
}

fileprivate func writeVirtualTableFunc(_ method: Method, genericTypeArgs: [TypeNode], projection: SwiftProjection, to output: IndentedTextOutputStream) throws {
    let (paramProjections, returnProjection) = try projection.getParamProjections(method: method, genericTypeArgs: genericTypeArgs)

    var abiParamNames = [String]()
    for paramProjection in paramProjections {
        if paramProjection.isArray { abiParamNames.append(paramProjection.arrayLengthName) }
        abiParamNames.append(paramProjection.name)
    }
    if let returnProjection {
        if returnProjection.isArray { abiParamNames.append(returnProjection.arrayLengthName) }
        abiParamNames.append(returnProjection.name)
    }

    try writeVirtualTableFuncImplementation(
            name: method.findAttribute(OverloadAttribute.self) ?? method.name,
            paramNames: abiParamNames,
            to: output) {
        // Ensure non-optional by reference params are non-null pointers
        for paramProjection in paramProjections {
            guard case .reference(in: _, out: _, optional: false) = paramProjection.passBy else { continue }
            output.writeFullLine("guard let \(paramProjection.name) else { throw COM.HResult.Error.pointer }")
        }
        if let returnProjection {
            output.writeFullLine("guard let \(returnProjection.name) else { throw COM.HResult.Error.pointer }")
        }

        // Declare the Swift representation of params
        var epilogueOutParamWithCleanupCount = 0
        for paramProjection in paramProjections {
            guard paramProjection.typeProjection.kind != .identity else { continue }
            if paramProjection.passBy.isOutput, paramProjection.typeProjection.kind != .inert {
                epilogueOutParamWithCleanupCount += 1
            }
            try writePrologueForParam(paramProjection, projection: projection, to: output)
        }

        // Set up the return value
        if let returnProjection {
            if returnProjection.typeProjection.kind == .identity {
                output.write("\(returnProjection.name).pointee = ")
            }
            else {
                if returnProjection.typeProjection.kind != .inert {
                    epilogueOutParamWithCleanupCount += 1
                }
                output.write("let \(returnProjection.swiftProjectionName) = ")
            }

            if case .return(nullAsError: true) = returnProjection.passBy {
                output.write("try \(SupportModule.nullResult).`catch`(")
            }
        }

        // Call the Swift implementation
        let methodKind = WinRTMethodKind(from: method)
        output.write("try ")
        output.write(methodKind == .delegateInvoke
            ? "this" : "this.\(SwiftProjection.toMemberName(method))")
        if methodKind != .propertyGetter {
            output.write("(")
            if methodKind == .eventAdder || methodKind == .eventRemover {
                assert(paramProjections.count == 1)
                output.write(methodKind == .eventAdder ? "adding: " : "removing: ")
            }
            for (index, paramProjection) in paramProjections.enumerated() {
                if index > 0 { output.write(", ") }
                if paramProjection.passBy != .value { output.write("&") }
                if paramProjection.typeProjection.kind == .identity {
                    output.write(paramProjection.name)
                    if paramProjection.passBy != .value { output.write(".pointee") }
                } else {
                    output.write(paramProjection.swiftProjectionName)
                }
            }
            output.write(")")
            if methodKind == .eventAdder { output.write(".token") }
        }

        if let returnProjection, case .return(nullAsError: true) = returnProjection.passBy {
            output.write(")") // NullResult.`catch`
        }
        output.endLine()

        // Convert out params to the ABI representation
        let epilogueRequiresCleanup = epilogueOutParamWithCleanupCount > 1
        if epilogueRequiresCleanup { output.writeFullLine("var _success = false") }

        for paramProjection in paramProjections {
            guard paramProjection.passBy.isOutput, paramProjection.typeProjection.kind != .identity else { continue }
            try writeEpilogueForOutParam(paramProjection, skipCleanup: !epilogueRequiresCleanup, projection: projection, to: output)
        }

        if let returnProjection, returnProjection.typeProjection.kind != .identity {
            try writeEpilogueForOutParam(returnProjection, skipCleanup: !epilogueRequiresCleanup, projection: projection, to: output)
        }

        if epilogueRequiresCleanup { output.writeFullLine("_success = true") }
    }
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

fileprivate func writePrologueForParam(_ paramProjection: ParamProjection, projection: SwiftProjection, to output: IndentedTextOutputStream) throws {
    if paramProjection.passBy.isInput {
        let declarator: SwiftVariableDeclarator = paramProjection.passBy.isOutput ? .var : .let
        output.write("\(declarator) \(paramProjection.swiftProjectionName) = \(paramProjection.projectionType).toSwift")
        switch paramProjection.typeProjection.kind {
            case .identity: fatalError("Case should have been ignored earlier.")
            case .inert, .allocating:
                output.write("(\(paramProjection.name))")
            case .array:
                output.write("(pointer: \(paramProjection.name), count: \(paramProjection.arrayLengthName))")
        }
    } else {
        output.write("var \(paramProjection.swiftProjectionName): \(paramProjection.typeProjection.swiftType)"
            + " = \(paramProjection.typeProjection.swiftDefaultValue)")
    }
    output.endLine()
}

fileprivate func writeEpilogueForOutParam(_ paramProjection: ParamProjection, skipCleanup: Bool, projection: SwiftProjection, to output: IndentedTextOutputStream) throws {
    precondition(paramProjection.passBy.isOutput)

    if paramProjection.typeProjection.kind == .array {
        output.writeFullLine(#"fatalError("Not implemented: out arrays")"#)
    }
    else {
        let isOptional: Bool
        if case .reference(in: _, out: _, optional: true) = paramProjection.passBy {
            isOptional = true
        } else {
            isOptional = false
        }

        if isOptional { output.write("if let \(paramProjection.name) { ") }

        output.write("\(paramProjection.name).pointee = ")
        if paramProjection.typeProjection.kind == .identity {
            output.write(paramProjection.swiftProjectionName)
        } else {
            if paramProjection.typeProjection.kind == .allocating { output.write ("try ") }
            output.write("\(paramProjection.projectionType).toABI(\(paramProjection.swiftProjectionName))")
        }

        if isOptional { output.write(" }") }
        
        output.endLine()

        if paramProjection.typeProjection.kind == .allocating, !skipCleanup {
            output.write("defer { ")
            output.write("if !_success, let \(paramProjection.name) { ")
            output.write("\(paramProjection.projectionType).release(&\(paramProjection.name).pointee)")
            output.write(" }")
            output.write(" }", endLine: true)
        }
    }
}