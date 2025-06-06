import Collections
import DotNetMetadata
import WindowsMetadata
import ProjectionModel
import CodeWriters
import struct Foundation.UUID

internal func writeCOMInteropExtension(abiType: BoundType, projection: Projection, to writer: SwiftSourceFileWriter) throws {
    let abiSwiftType = try projection.toABIType(abiType)
    let visibility: SwiftVisibility = abiType.genericArgs.isEmpty ? .public : .internal

    // func uuidof(_: SWRT_IFoo.Type) -> COMInterfaceID
    try writer.writeFunc(
            visibility: visibility, name: "uuidof",
            params: [ .init(name: "_", type: abiSwiftType.metatype()) ],
            returnType: SupportModules.COM.comInterfaceID) { writer in
        writer.output.writeFullLine(try toIIDExpression(WindowsMetadata.getInterfaceID(abiType)))
    }

    // extension COM.COMInterop where ABIStruct == SWRT_IFoo
    try writer.writeExtension(type: SupportModules.COM.comInterop, whereClauses: [ "ABIStruct == \(abiSwiftType)" ]) { writer in
        let methodKind = try ABIMethodKind.forABITypeMethods(definition: abiType.definition)
        for method in abiType.definition.methods {
            // For delegates, only expose the Invoke method
            guard abiType.definition is InterfaceDefinition || method.name == "Invoke" else { continue }
            try writeCOMInteropMethod(
                method, typeGenericArgs: abiType.genericArgs,
                visibility: visibility, methodKind: methodKind,
                projection: projection, to: writer)
        }
    }
}

internal func toIIDExpression(_ uuid: UUID) throws -> String {
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

fileprivate func writeCOMInteropMethod(
        _ method: Method, typeGenericArgs: [TypeNode],
        visibility: SwiftVisibility, methodKind: ABIMethodKind,
        projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    let abiMethodName = try method.findAttribute(OverloadAttribute.self)?.methodName ?? method.name
    let (paramBindings, returnBinding) = try projection.getParamBindings(
        method: method, genericTypeArgs: typeGenericArgs, abiKind: methodKind)

    // Generic instantiations can exist in multiple modules, so use internal visibility to avoid collisions
    try writer.writeFunc(
            visibility: visibility,
            name: Projection.toInteropMethodName(method),
            params: paramBindings.map { $0.toSwiftParam() },
            throws: true, returnType: returnBinding.map { $0.typeBinding.swiftType }) { writer in
        try writeSwiftToABICall(
            abiMethodName: abiMethodName,
            params: paramBindings,
            returnParam: returnBinding,
            returnCOMReference: methodKind == .activationFactory || methodKind == .composableFactory,
            to: writer)
    }
}

fileprivate func writeSwiftToABICall(
        abiMethodName: String,
        params: [ParamBinding],
        returnParam: ParamBinding?,
        returnCOMReference: Bool,
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
        let typeBinding = param.typeBinding
        if param.typeBinding.kind == .identity {
            addAbiArg(param.name, byRef: param.passBy != .value, array: false)
            continue
        }

        let declarator: SwiftVariableDeclarator = param.passBy.isReference || typeBinding.kind != .pod ? .var : .let
        if param.passBy.isOutput { needsOutParamsEpilogue = true }

        if param.passBy.isOutput && !param.passBy.isInput {
            writer.writeStatement("\(declarator) \(param.abiBindingName): \(typeBinding.abiType) = \(typeBinding.abiDefaultValue)")
        }
        else {
            let tryPrefix = typeBinding.kind == .pod ? "" : "try "
            writer.writeStatement("\(declarator) \(param.abiBindingName) = "
                + "\(tryPrefix)\(typeBinding.bindingType).toABI(\(param.name))")
        }

        if typeBinding.kind != .pod {
            writer.writeStatement("defer { \(typeBinding.bindingType).release(&\(param.abiBindingName)) }")
        }

        addAbiArg(param.abiBindingName, byRef: param.passBy.isReference, array: typeBinding.kind == .array)
    }

    func writeOutParamsEpilogue() throws {
        for param in params {
            let typeBinding = param.typeBinding
            if typeBinding.kind != .identity && param.passBy.isOutput {
                if typeBinding.kind == .pod {
                    writer.writeStatement("\(param.name) = \(typeBinding.bindingType).fromABI(\(param.abiBindingName))")
                }
                else {
                    writer.writeStatement("\(param.name) = \(typeBinding.bindingType).fromABI(consuming: &\(param.abiBindingName))")
                }
            }
        }
    }

    func writeCall() throws {
        writer.writeStatement("try WinRTError.fromABI("
            + "this.pointee.VirtualTable.pointee.\(abiMethodName)("
            + "\(abiArgs.joined(separator: ", "))))")
    }

    guard let returnParam else {
        try writeCall()
        if needsOutParamsEpilogue { try writeOutParamsEpilogue() }
        return
    }

    // Value-returning functions
    let returnTypeBinding = returnParam.typeBinding
    writer.writeStatement("var \(returnParam.name): \(returnTypeBinding.abiType) = \(returnTypeBinding.abiDefaultValue)")
    addAbiArg(returnParam.name, byRef: true, array: returnTypeBinding.kind == .array)
    try writeCall()

    if needsOutParamsEpilogue {
        // Don't leak the result if we fail in the out params epilogue
        if returnTypeBinding.kind != .identity && returnTypeBinding.kind != .pod {
            writer.writeStatement("defer { \(returnTypeBinding.bindingType).release(&\(returnParam.name)) }")
        }

        try writeOutParamsEpilogue()
    }

    // Handle the return value
    let returnValue: String
    switch returnTypeBinding.kind {
        case .identity where returnCOMReference:
            writer.writeStatement("guard let \(returnParam.name) else { throw COMError.pointer }")
            returnValue = "\(SupportModules.COM.comReference)(transferringRef: \(returnParam.name))"
        case .identity where !returnCOMReference:
            returnValue = returnParam.name
        case .pod:
            returnValue = "\(returnTypeBinding.bindingType).fromABI(\(returnParam.name))"
        default:
            returnValue = "\(returnTypeBinding.bindingType).fromABI(consuming: &\(returnParam.name))"
    }

    writer.writeReturnStatement(value: returnValue)
}