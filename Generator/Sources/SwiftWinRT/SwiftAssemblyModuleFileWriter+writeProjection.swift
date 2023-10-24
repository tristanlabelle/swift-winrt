import CodeWriters
import Collections
import DotNetMetadata
import WindowsMetadata
import struct Foundation.UUID

extension SwiftAssemblyModuleFileWriter {
    func writeProjection(_ type: BoundType) throws {
        // TODO: Support generic interfaces/delegates

        if let interfaceDefinition = type.definition as? InterfaceDefinition {
            // Generic interfaces have no projection, only their instantiations do
            try writeInterfaceProjection(interfaceDefinition.bind(genericArgs: type.genericArgs))
        }
        else if let classDefinition = type.definition as? ClassDefinition {
            assert(type.genericArgs.isEmpty)
            try writeClassProjection(classDefinition)
        }
        else if let enumDefinition = type.definition as? EnumDefinition {
            assert(type.genericArgs.isEmpty)
            try writeEnumProjection(enumDefinition)
        }
        else if let structDefinition = type.definition as? StructDefinition {
            assert(type.genericArgs.isEmpty)
            try writeStructProjection(structDefinition)
        }
    }

    private func writeInterfaceProjection(_ interface: BoundInterface) throws {
        let projectionTypeName = try projection.toProjectionTypeName(interface.definition)
        try sourceFileWriter.writeClass(
                visibility: SwiftProjection.toVisibility(interface.definition.visibility),
                final: true, name: projectionTypeName,
                base: .identifier(name: "WinRTProjectionBase", genericArgs: [.identifier(name: projectionTypeName)]),
                protocolConformances: [
                    .identifier("WinRTProjection"), .identifier(name: try projection.toProtocolName(interface.definition))
                ]) { writer throws in

            try writeGenericTypeAliases(interfaces: [interface], to: writer)
            try writeWinRTProjectionConformance(type: interface.asType, interface: interface, to: writer)
            try writeInterfaceImplementations(interface.asType, to: writer)
        }
    }

    private func writeClassProjection(_ classDefinition: ClassDefinition) throws {
        let typeName = try projection.toTypeName(classDefinition)
        let isStatic = classDefinition.isAbstract && classDefinition.isSealed
        try sourceFileWriter.writeClass(
                visibility: SwiftProjection.toVisibility(classDefinition.visibility), final: true, name: typeName,
                base: isStatic ? nil : .identifier(name: "WinRTProjectionBase", genericArgs: [.identifier(name: typeName)]),
                protocolConformances: isStatic ? [] : [.identifier("WinRTProjection")]) { writer throws in

            try writeGenericTypeAliases(interfaces: classDefinition.baseInterfaces.map { try $0.interface }, to: writer)

            if isStatic {
                writer.writeInit(visibility: .private) { writer in }
            }
            else {
                let defaultInterface = try DefaultAttribute.getDefaultInterface(classDefinition)!
                try writeWinRTProjectionConformance(type: classDefinition.bindType(), interface: defaultInterface, to: writer)
                try writeInterfaceImplementations(classDefinition.bindType(), to: writer)
            }

            for staticAttribute in try classDefinition.getAttributes(StaticAttribute.self) {
                _ = try writeNonDefaultInterfaceImplementation(
                    staticAttribute.interface.bind(), staticOf: classDefinition, to: writer)
            }
        }
    }

    private func writeEnumProjection(_ enumDefinition: EnumDefinition) throws {
        try sourceFileWriter.writeExtension(
                name: projection.toTypeName(enumDefinition),
                protocolConformances: [SwiftType.chain("WindowsRuntime", "EnumProjection")]) { writer in

            writer.writeTypeAlias(visibility: .public, name: "CEnum",
                target: .chain(projection.abiModuleName, try CAbi.mangleName(type: enumDefinition.bindType())))
        }
    }

    private func writeStructProjection(_ structDefinition: StructDefinition) throws {
        let abiType = SwiftType.chain(projection.abiModuleName, try CAbi.mangleName(type: structDefinition.bindType()))

        sourceFileWriter.writeExtension(
                name: try projection.toTypeName(structDefinition),
                protocolConformances: [SwiftType.chain("COM", "ABIInertProjection")]) { writer in

            writer.writeTypeAlias(visibility: .public, name: "SwiftValue", target: .`self`)
            writer.writeTypeAlias(visibility: .public, name: "ABIValue", target: abiType)

            writer.writeComputedProperty(
                    visibility: .public, static: true, name: "abiDefaultValue", type: abiType) { writer in
                writer.writeStatement(".init()")
            }
            writer.writeFunc(
                    visibility: .public, static: true, name: "toSwift",
                    parameters: [.init(label: "_", name: "value", type: abiType)], 
                    returnType: .`self`) { writer in
                writer.writeNotImplemented()
            }
            writer.writeFunc(
                    visibility: .public, static: true, name: "toABI",
                    parameters: [.init(label: "_", name: "value", type: .`self`)],
                    returnType: abiType) { writer in
                writer.writeNotImplemented()
            }
        }
    }

    /// Gathers all generic arguments from the given interfaces and writes them as type aliases
    /// For example, if an interface is IMap<String, Int32>, write K = String and V = Int32
    private func writeGenericTypeAliases(interfaces: [BoundInterface], to writer: SwiftRecordBodyWriter) throws {
        var typeAliases = OrderedDictionary<String, SwiftType>()

        for interface in interfaces {
            for (index, genericArg) in interface.genericArgs.enumerated() {
                let genericParamName = interface.definition.genericParams[index].name
                if typeAliases[genericParamName] == nil {
                    typeAliases[genericParamName] = try projection.toType(genericArg)
                }
            }
        }

        for (name, type) in typeAliases {
            writer.writeTypeAlias(visibility: .public, name: name, target: type)
        }
    }

    private func writeWinRTProjectionConformance(type: BoundType, interface: BoundInterface, to writer: SwiftRecordBodyWriter) throws {
        let abiName = try CAbi.mangleName(type: interface.asType)

        writer.writeTypeAlias(visibility: .public, name: "SwiftObject",
            target: try projection.toType(type.asNode).unwrapOptional())
        writer.writeTypeAlias(visibility: .public, name: "COMInterface",
            target: .chain(projection.abiModuleName, abiName))
        writer.writeTypeAlias(visibility: .public, name: "COMVirtualTable",
            target: .chain(projection.abiModuleName, abiName + WinRTTypeName.midlVirtualTableSuffix))

        // TODO: Support generic interfaces
        let guid = try interface.definition.findAttribute(WindowsMetadata.GuidAttribute.self)!
        writer.writeStoredProperty(visibility: .public, static: true, declarator: .let, name: "iid",
            initialValue: try Self.toIIDExpression(guid))

        let runtimeClassName = WinRTTypeName.from(type: type)!.description
        writer.writeStoredProperty(visibility: .public, static: true, declarator: .let, name: "runtimeClassName",
            initialValue: "\"\(runtimeClassName)\"")
    }

    private static func toIIDExpression(_ uuid: UUID) throws -> String {
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
        return "IID(\(arguments.joined(separator: ", ")))"
    }

    private func writeInterfaceImplementations(_ type: BoundType, to writer: SwiftRecordBodyWriter) throws {
        var recursiveInterfaces = [BoundInterface]()

        func visit(_ interface: BoundInterface) throws {
            guard !recursiveInterfaces.contains(interface) else { return }
            recursiveInterfaces.append(interface)

            for baseInterface in interface.definition.baseInterfaces {
                try visit(baseInterface.interface.bindGenericParams(
                    typeArgs: interface.genericArgs, methodArgs: nil))
            }
        }

        var defaultInterface: BoundInterface?
        if let interfaceDefinition = type.definition as? InterfaceDefinition {
            let interface = interfaceDefinition.bind(genericArgs: type.genericArgs)
            defaultInterface = interface
            try visit(interface)
        }

        for baseInterface in type.definition.baseInterfaces {
            let interface = try baseInterface.interface.bindGenericParams(
                typeArgs: type.genericArgs, methodArgs: nil)
            if try defaultInterface == nil && baseInterface.hasAttribute(DefaultAttribute.self) {
                defaultInterface = interface
            }
            try visit(interface)
        }

        var nonDefaultInterfaceStoredProperties = [String]()
        for interface in recursiveInterfaces {
            writer.output.writeLine("// \(WinRTTypeName.from(type: interface.asType)!.description)")
            if interface == defaultInterface {
                try writeMethodsProjection(interface: interface, static: false, thisName: "comPointer", to: writer)
            }
            else {
                let storedProperty = try writeNonDefaultInterfaceImplementation(interface, to: writer)
                nonDefaultInterfaceStoredProperties.append(storedProperty)
            }
        }

        if !nonDefaultInterfaceStoredProperties.isEmpty {
            writer.writeDeinit { writer in
                for storedProperty in nonDefaultInterfaceStoredProperties {
                    writer.writeStatement("if let \(storedProperty) { IUnknownPointer.release(\(storedProperty)) }")
                }
            }
        }
    }

    private func writeNonDefaultInterfaceImplementation(
        _ interface: BoundInterface, staticOf: ClassDefinition? = nil, to writer: SwiftRecordBodyWriter) throws -> String {

        // private [static] var _istringable: UnsafeMutablePointer<__x_ABI_CIStringable>! = nil
        let interfaceName = try projection.toTypeName(interface.definition, namespaced: false)
        let storedPropertyName = "_" + Casing.pascalToCamel(interfaceName)
        let abiName = try CAbi.mangleName(type: interface.asType)
        let iid = try Self.toIIDExpression(interface.definition.findAttribute(WindowsMetadata.GuidAttribute.self)!)
        writer.writeStoredProperty(visibility: .private, static: staticOf != nil, declarator: .var, name: storedPropertyName,
            type: .optional(wrapped: .identifier("UnsafeMutablePointer", genericArgs: [.identifier(abiName)]), implicitUnwrap: true),
            initialValue: "nil")

        // private [static] func _initIStringable() throws {
        //     guard _istringable == nil else { return }
        //     _istringable = try WindowsRuntime.ActivationFactory.getPointer(activatableId: "Windows.Foundation.IStringable", iid: IID(__x_ABI_CIStringable.self)
        // }
        let initFunc = "_init" + interfaceName
        writer.writeFunc(visibility: .private, static: staticOf != nil, name: initFunc, throws: true) {
            $0.writeStatement("guard \(storedPropertyName) == nil else { return }")
            if let staticOf {
                let activatableId = WinRTTypeName.from(type: staticOf.bindType())!.description
                $0.writeStatement("\(storedPropertyName) = try WindowsRuntime.ActivationFactory.getPointer("
                    + "activatableId: \"\(activatableId)\", iid: \(iid))")
            }
            else {
                $0.writeStatement("\(storedPropertyName) = try _queryInterfacePointer(\(iid)).cast(to: \(abiName).self)")
            }
        }

        try writeMethodsProjection(interface: interface, static: staticOf != nil, thisName: storedPropertyName, initThisFunc: initFunc, to: writer)

        return storedPropertyName
    }

    private func writeMethodsProjection(
            interface: BoundInterface, static: Bool, thisName: String, initThisFunc: String? = nil,
            to writer: SwiftRecordBodyWriter) throws {
        // TODO: Support generic interfaces
        let interfaceDefinition = interface.definition
        for property in interfaceDefinition.properties {
            if let getter = try property.getter, getter.isPublic {
                try writer.writeComputedProperty(
                    visibility: .public,
                    static: `static`,
                    name: projection.toMemberName(property),
                    type: projection.toReturnType(property.type),
                    throws: true) { writer throws in

                    try writeMethodProjection(getter, thisName: thisName, initThisFunc: initThisFunc, to: &writer)
                }
            }

            if let setter = try property.setter, setter.isPublic {
                try writer.writeFunc(
                    visibility: .public,
                    static: `static`,
                    name: projection.toMemberName(property),
                    parameters: [SwiftParameter(
                        label: "_", name: "newValue",
                        type: projection.toType(property.type))],
                    throws: true) { writer throws in

                    try writeMethodProjection(setter, thisName: thisName, initThisFunc: initThisFunc, to: &writer)
                }
            }
        }

        for method in interfaceDefinition.methods {
            guard method.isPublic, method.nameKind == .regular else { continue }

            try writer.writeFunc(
                visibility: .public,
                static: `static`,
                name: projection.toMemberName(method),
                parameters: method.params.map(projection.toParameter),
                throws: true,
                returnType: projection.toReturnTypeUnlessVoid(method.returnType)) { writer throws in

                try writeMethodProjection(method, thisName: thisName, initThisFunc: initThisFunc, to: &writer)
            }
        }
    }

    private func writeMethodProjection(_ method: Method, thisName: String, initThisFunc: String? = nil, to writer: inout SwiftStatementWriter) throws {
        if let initThisFunc { writer.writeStatement("try \(initThisFunc)()") }

        var abiArgs = [thisName]
        for param in try method.params {
            guard let paramName = param.name else {
                writer.writeNotImplemented()
                return
            }

            let typeProjection = try projection.getTypeProjection(param.type)
            guard let abi = typeProjection.abi else {
                writer.writeNotImplemented()
                return
            }

            if !abi.identity {
                if abi.inert {
                    writer.writeStatement("let \(paramName) = \(abi.projectionType).toABI(\(paramName))")
                }
                else {
                    writer.writeStatement("let \(paramName) = try \(abi.projectionType).toABI(\(paramName))")
                    writer.writeStatement("defer { \(abi.projectionType).release(\(paramName)) }")
                }
            }

            abiArgs.append(paramName)
        }

        func writeCall() throws {
            let abiMethodName = try method.findAttribute(OverloadAttribute.self) ?? method.name
            writer.writeStatement("try HResult.throwIfFailed(\(thisName).pointee.lpVtbl.pointee.\(abiMethodName)(\(abiArgs.joined(separator: ", "))))")
        }

        if try !method.hasReturnValue {
            try writeCall()
            return
        }

        let returnTypeProjection = try projection.getTypeProjection(method.returnType)
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