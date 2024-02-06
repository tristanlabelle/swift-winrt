import Collections
import DotNetMetadata
import WindowsMetadata
import ProjectionGenerator
import CodeWriters

/// Writes a file that extendends COMInterop<I> for every COM interface with
/// methods that translate from the Swift shape to the ABI shape.
internal func writeCOMInteropExtensionsFile(module: SwiftProjection.Module, toPath path: String) throws {
    let writer = SwiftSourceFileWriter(output: FileTextOutputStream(path: path))

    writer.writeCommentLine("Generated by swift-winrt")
    writer.writeCommentLine("swiftlint:disable all", groupWithNext: false)

    writer.writeImport(module: module.projection.abiModuleName)
    writer.writeImport(module: "COM")
    writer.writeImport(module: "WindowsRuntime")

    for referencedModule in module.references {
        guard !referencedModule.isEmpty else { continue }
        writer.writeImport(module: referencedModule.name)
    }

    writer.writeImport(module: "Foundation", struct: "UUID")

    // Gather bound interfaces, generic or not, sorted by ABI name
    var boundInterfaces = [(interface: BoundInterface, abiName: String)]()
    for (_, typeDefinitions) in module.typeDefinitionsByNamespace {
        for typeDefinition in typeDefinitions {
            guard typeDefinition.genericArity == 0 else { continue }
            guard let interfaceDefinition = typeDefinition as? InterfaceDefinition else { continue }
            let boundInterface = interfaceDefinition.bind()
            boundInterfaces.append((boundInterface, try CAbi.mangleName(type: boundInterface.asBoundType)))
        }
    }

    for (typeDefinition, instantiations) in module.closedGenericTypesByDefinition {
        guard let interfaceDefinition = typeDefinition as? InterfaceDefinition else { continue }
        for genericArgs in instantiations {
            let boundInterface = interfaceDefinition.bind(genericArgs: genericArgs)
            boundInterfaces.append((boundInterface, try CAbi.mangleName(type: boundInterface.asBoundType)))
        }
    }

    // Write the COMInterop<I> extension for each interface
    boundInterfaces.sort { $0.abiName < $1.abiName }
    for (boundInterface, abiName) in boundInterfaces {
        // IReference is special cased, with a single definition for all generic instantiations
        guard boundInterface.definition.fullName != "Windows.Foundation.IReference`1" else { continue }
        try writeCOMInteropExtension(interface: boundInterface, abiName: abiName, module: module, to: writer)
    }
}

fileprivate func writeCOMInteropExtension(interface: BoundInterface, abiName: String, module: SwiftProjection.Module, to writer: SwiftSourceFileWriter) throws {
    let qualifiedAbiName = "\(module.projection.abiModuleName).\(abiName)"

    // Mark the COM interface as being IInspectable-compatible.
    writer.output.writeFullLine(grouping: .never, "extension \(qualifiedAbiName): @retroactive WindowsRuntime.COMIInspectableStruct {}")

    try writer.writeExtension(name: "COMInterop", whereClauses: [ "Interface == \(qualifiedAbiName)" ]) { writer in
        for method in interface.definition.methods {
            let abiMethodName = try method.findAttribute(OverloadAttribute.self) ?? method.name
            let (paramProjections, returnProjection) = try module.projection.getParamProjections(method: method, genericTypeArgs: interface.genericArgs)
            // Generic instantiations can exist in multiple modules, so use internal visibility to avoid collisions
            let visibility: SwiftVisibility = interface.genericArgs.isEmpty ? .public : .internal
            try writer.writeFunc(
                    visibility: visibility, name: Casing.pascalToCamel(abiMethodName),
                    params: paramProjections.map { $0.toSwiftParam() },
                    throws: true, returnType: returnProjection.map { $0.typeProjection.swiftType }) { writer in
                try writeSwiftToAbiCall(
                    abiMethodName: abiMethodName,
                    params: paramProjections,
                    returnParam: returnProjection,
                    to: writer)
            }
        }
    }
}

fileprivate func writeSwiftToAbiCall(
        abiMethodName: String,
        params: [ParamProjection],
        returnParam: ParamProjection?,
        to writer: SwiftStatementWriter) throws {

    var abiArgs = ["this"]
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
        writer.writeStatement("try WinRTError.throwIfFailed("
            + "this.pointee.lpVtbl.pointee.\(abiMethodName)("
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
    let returnValue: String = switch returnTypeProjection.kind {
        case .identity: returnParam.name
        case .inert: "\(returnTypeProjection.projectionType).toSwift(\(returnParam.name))"
        default: "\(returnTypeProjection.projectionType).toSwift(consuming: &\(returnParam.name))"
    }

    writer.writeReturnStatement(value: returnValue)
}