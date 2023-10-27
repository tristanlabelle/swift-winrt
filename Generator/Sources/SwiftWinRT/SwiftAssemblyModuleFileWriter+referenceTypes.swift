import CodeWriters
import Collections
import DotNetMetadata
import WindowsMetadata
import struct Foundation.UUID

extension SwiftAssemblyModuleFileWriter {
    /// Gathers all generic arguments from the given interfaces and writes them as type aliases
    /// For example, if an interface is IMap<String, Int32>, write K = String and V = Int32
    internal func writeGenericTypeAliases(interfaces: [BoundInterface], to writer: SwiftRecordBodyWriter) throws {
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

    internal func writeWinRTProjectionConformance(interfaceOrDelegate: BoundType, classDefinition: ClassDefinition? = nil, to writer: SwiftRecordBodyWriter) throws {
        writer.writeTypeAlias(visibility: .public, name: "SwiftObject",
            target: try projection.toType(classDefinition?.bindNode() ?? interfaceOrDelegate.asNode).unwrapOptional())

        let abiName = try CAbi.mangleName(type: interfaceOrDelegate)
        writer.writeTypeAlias(visibility: .public, name: "COMInterface",
            target: .chain(projection.abiModuleName, abiName))
        writer.writeTypeAlias(visibility: .public, name: "COMVirtualTable",
            target: .chain(projection.abiModuleName, abiName + WinRTTypeName.midlVirtualTableSuffix))

        // TODO: Support generic interfaces
        let guid = try interfaceOrDelegate.definition.findAttribute(WindowsMetadata.GuidAttribute.self)!
        writer.writeStoredProperty(visibility: .public, static: true, declarator: .let, name: "iid",
            initialValue: try Self.toIIDExpression(guid))

        if interfaceOrDelegate.definition is InterfaceDefinition {
            // Delegates are IUnknown interfaces, not IInspectable
            let runtimeClassName = WinRTTypeName.from(type: classDefinition?.bindType() ?? interfaceOrDelegate)!.description
            writer.writeStoredProperty(visibility: .public, static: true, declarator: .let, name: "runtimeClassName",
                initialValue: "\"\(runtimeClassName)\"")
        }
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

    internal func writeInterfaceImplementations(_ type: BoundType, to writer: SwiftRecordBodyWriter) throws {
        var recursiveInterfaces = [BoundInterface]()

        func visit(_ interface: BoundInterface) throws {
            guard !recursiveInterfaces.contains(interface) else { return }
            recursiveInterfaces.append(interface)

            for baseInterface in interface.definition.baseInterfaces {
                try visit(baseInterface.interface.bindGenericParams(
                    typeArgs: interface.genericArgs))
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
                typeArgs: type.genericArgs)
            if try defaultInterface == nil && baseInterface.hasAttribute(DefaultAttribute.self) {
                defaultInterface = interface
            }
            try visit(interface)
        }

        var nonDefaultInterfaceStoredProperties = [String]()
        for interface in recursiveInterfaces {
            writer.output.writeLine("// \(WinRTTypeName.from(type: interface.asBoundType)!.description)")
            if interface == defaultInterface {
                try writeMemberImplementations(interfaceOrDelegate: interface.asBoundType, static: false, thisName: "comPointer", to: writer)
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

    internal func writeNonDefaultInterfaceImplementation(
        _ interface: BoundInterface, staticOf: ClassDefinition? = nil, to writer: SwiftRecordBodyWriter) throws -> String {

        // private [static] var _istringable: UnsafeMutablePointer<__x_ABI_CIStringable>! = nil
        let interfaceName = try projection.toTypeName(interface.definition, namespaced: false)
        let storedPropertyName = "_" + Casing.pascalToCamel(interfaceName)
        let abiName = try CAbi.mangleName(type: interface.asBoundType)
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

        try writeMemberImplementations(
            interfaceOrDelegate: interface.asBoundType, static: staticOf != nil,
            thisName: storedPropertyName, initThisFunc: initFunc, to: writer)

        return storedPropertyName
    }

    internal func writeMemberImplementations(
            interfaceOrDelegate: BoundType, static: Bool, thisName: String, initThisFunc: String? = nil,
            to writer: SwiftRecordBodyWriter) throws {
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

                    try writeMethodImplementations(getter, genericTypeArgs: interfaceOrDelegate.genericArgs,
                        thisName: thisName, initThisFunc: initThisFunc, to: &writer)
                }
            }

            if let setter = try property.setter, setter.isPublic {
                try writer.writeFunc(
                    visibility: .public,
                    static: `static`,
                    name: projection.toMemberName(property),
                    parameters: [SwiftParameter(label: "_", name: "newValue", type: swiftPropertyType)],
                    throws: true) { writer throws in

                    try writeMethodImplementations(setter , genericTypeArgs: interfaceOrDelegate.genericArgs,
                        thisName: thisName, initThisFunc: initThisFunc, to: &writer)
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

                try writeMethodImplementations(method, genericTypeArgs: interfaceOrDelegate.genericArgs,
                    thisName: thisName, initThisFunc: initThisFunc, to: &writer)
            }
        }
    }

    private func writeMethodImplementations(
            _ method: Method, genericTypeArgs: [TypeNode],
            thisName: String, initThisFunc: String? = nil,
            to writer: inout SwiftStatementWriter) throws {
        if let initThisFunc { writer.writeStatement("try \(initThisFunc)()") }

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