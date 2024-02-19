import Collections
import DotNetMetadata
import WindowsMetadata
import ProjectionGenerator
import CodeWriters
import struct Foundation.UUID

/// Writes a file that extends COMInterop<I> for every COM interface with
/// methods that translate from the Swift shape to the ABI shape.
internal func writeCOMInteropExtensionsFile(module: SwiftProjection.Module, toPath path: String) throws {
    let writer = SwiftSourceFileWriter(output: FileTextOutputStream(path: path, directoryCreation: .ancestors))
    writeGeneratedCodePreamble(to: writer)
    writeModulePreamble(module, to: writer)

    // Gather bound interfaces and delegates, generic or not, sorted by ABI name
    var boundAbiTypes = [(interface: BoundType, abiName: String)]()
    for (_, typeDefinitions) in module.typeDefinitionsByNamespace {
        for typeDefinition in typeDefinitions {
            guard typeDefinition.genericArity == 0 else { continue }
            guard typeDefinition is InterfaceDefinition || typeDefinition is DelegateDefinition else { continue }
            let boundType = typeDefinition.bindType()
            boundAbiTypes.append((boundType, try CAbi.mangleName(type: boundType)))
        }
    }

    for (typeDefinition, instantiations) in module.closedGenericTypesByDefinition {
        assert(typeDefinition is InterfaceDefinition || typeDefinition is DelegateDefinition)
        for genericArgs in instantiations {
            let boundType = typeDefinition.bindType(genericArgs: genericArgs)
            boundAbiTypes.append((boundType, try CAbi.mangleName(type: boundType)))
        }
    }

    // Write the COMInterop<I> extension for each interface
    boundAbiTypes.sort { $0.abiName < $1.abiName }
    for (boundType, abiName) in boundAbiTypes {
        // IReference is special cased, with a single definition for all generic instantiations
        guard boundType.definition.fullName != "Windows.Foundation.IReference`1" else { continue }
        try writeCOMInteropExtension(abiType: boundType, abiName: abiName, module: module, to: writer)
    }
}

fileprivate enum ABIInterfaceUsage {
    case activationFactory
    case compositionFactory
    case other
}

fileprivate func getABIInterfaceUsage(_ typeDefinition: TypeDefinition) throws -> ABIInterfaceUsage {
    if let classDefinition = try typeDefinition.findAttribute(ExclusiveToAttribute.self) {
        for activatableAttribute in try classDefinition.getAttributes(ActivatableAttribute.self) {
            if activatableAttribute.factory == typeDefinition {
                return .activationFactory
            }
        }

        // for composableAttribute in try classDefinition.getAttributes(ComposableAttribute.self) {
        //     if composableAttribute.factory == typeDefinition {
        //         return .activationFactory
        //     }
        // }
    }
    return .other
}

fileprivate func writeCOMInteropExtension(abiType: BoundType, abiName: String, module: SwiftProjection.Module, to writer: SwiftSourceFileWriter) throws {
    let qualifiedAbiName = "\(module.projection.abiModuleName).\(abiName)"
    let visibility: SwiftVisibility = abiType.genericArgs.isEmpty ? .public : .internal

    if abiType.definition is InterfaceDefinition {
        // COM interfaces for WinRT interfaces are IInspectable-compatible. This is not true for delegates.
        // @retroactive is only supported in Swift 5.10 and above.
        let group = writer.output.allocateVerticalGrouping()
        writer.output.writeFullLine(grouping: group, "#if swift(>=5.10)")
        writer.output.writeFullLine(grouping: group, "extension \(qualifiedAbiName): @retroactive \(SupportModule.comIInspectableStruct) {}")
        writer.output.writeFullLine(grouping: group, "#else")
        writer.output.writeFullLine(grouping: group, "extension \(qualifiedAbiName): \(SupportModule.comIInspectableStruct) {}")
        writer.output.writeFullLine(grouping: group, "#endif")
    }

    try writer.writeExtension(name: "COMInterop", whereClauses: [ "Interface == \(qualifiedAbiName)" ]) { writer in
        // static let iid: COMInterfaceID = COMInterfaceID(...)
        writer.writeStoredProperty(visibility: visibility, static: true, declarator: .let, name: "iid",
            initialValue: try toIIDExpression(WindowsMetadata.getInterfaceID(abiType)))

        for method in abiType.definition.methods {
            // For delegates, only expose the Invoke method
            guard abiType.definition is InterfaceDefinition || method.name == "Invoke" else { continue }

            let abiMethodName = try method.findAttribute(OverloadAttribute.self) ?? method.name
            var (paramProjections, returnProjection) = try module.projection.getParamProjections(method: method, genericTypeArgs: abiType.genericArgs)

            switch try getABIInterfaceUsage(abiType.definition) {
                case .activationFactory:
                    // Prevent the return value from being projected to Swift.
                    // Activation factory methods are called in class constructors,
                    // which need the resulting COM pointer for initialization.
                    let oldReturnProjection = returnProjection!
                    let pointerType = oldReturnProjection.typeProjection.abiType
                    returnProjection = ParamProjection(
                        name: oldReturnProjection.name,
                        typeProjection: TypeProjection(
                            swiftType: pointerType,
                            swiftDefaultValue: .expression("nil"),
                            projectionType: .void, // No projection needed
                            kind: .identity,
                            abiType: pointerType,
                            abiDefaultValue: .expression("nil")),
                        passBy: oldReturnProjection.passBy)
                default: break
            }

            // Generic instantiations can exist in multiple modules, so use internal visibility to avoid collisions
            try writer.writeFunc(
                    visibility: visibility,
                    name: SwiftProjection.toInteropMethodName(method),
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

fileprivate func toIIDExpression(_ uuid: UUID) throws -> String {
    func toPrefixedPaddedHex<Value: UnsignedInteger & FixedWidthInteger>(
        _ value: Value,
        minimumLength: Int = MemoryLayout<Value>.size * 2) -> String {

        var hex = String(value, radix: 16, uppercase: true)
        if hex.count < minimumLength {
            hex.insert(contentsOf: String(repeating: "0", count: minimumLength - hex.count), at: hex.startIndex)
        }
        hex.insert(contentsOf: "0x", at: hex.startIndex)
        return hex
    }

    let uuid = uuid.uuid
    let arguments = [
        toPrefixedPaddedHex((UInt32(uuid.0) << 24) | (UInt32(uuid.1) << 16) | (UInt32(uuid.2) << 8) | (UInt32(uuid.3) << 0)),
        toPrefixedPaddedHex((UInt16(uuid.4) << 8) | (UInt16(uuid.5) << 0)),
        toPrefixedPaddedHex((UInt16(uuid.6) << 8) | (UInt16(uuid.7) << 0)),
        toPrefixedPaddedHex((UInt16(uuid.8) << 8) | (UInt16(uuid.9) << 0)),
        toPrefixedPaddedHex(
            (UInt64(uuid.10) << 40) | (UInt64(uuid.11) << 32)
            | (UInt64(uuid.12) << 24) | (UInt64(uuid.13) << 16)
            | (UInt64(uuid.14) << 8) | (UInt64(uuid.15) << 0),
            minimumLength: 12)
    ]
    return "COMInterfaceID(\(arguments.joined(separator: ", ")))"
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