import CodeWriters
import Collections
import DotNetMetadata
import WindowsMetadata
import struct Foundation.UUID

extension SwiftAssemblyModuleFileWriter {
    /// Gathers all generic arguments from the given interfaces and writes them as type aliases
    /// For example, if an interface is IMap<String, Int32>, write K = String and V = Int32
    internal func writeGenericTypeAliases(interfaces: [BoundInterface], to writer: SwiftTypeDefinitionWriter) throws {
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

    internal func writeWinRTProjectionConformance(interfaceOrDelegate: BoundType, classDefinition: ClassDefinition? = nil, to writer: SwiftTypeDefinitionWriter) throws {
        writer.writeTypeAlias(visibility: .public, name: "SwiftObject",
            target: try projection.toType(classDefinition?.bindNode() ?? interfaceOrDelegate.asNode).unwrapOptional())

        let abiName = try CAbi.mangleName(type: interfaceOrDelegate)
        writer.writeTypeAlias(visibility: .public, name: "COMInterface",
            target: .chain(projection.abiModuleName, abiName))
        writer.writeTypeAlias(visibility: .public, name: "COMVirtualTable",
            target: .chain(projection.abiModuleName, abiName + WinRTTypeName.midlVirtualTableSuffix))

        writer.writeStoredProperty(visibility: .public, static: true, declarator: .let, name: "iid",
            initialValue: try Self.toIIDExpression(WindowsMetadata.getInterfaceID(interfaceOrDelegate)))

        if classDefinition == nil {
            writer.writeComputedProperty(
                visibility: .public, static: true, name: "virtualTablePointer",
                type: .identifier("COMVirtualTablePointer"),
                get: { writer in writer.writeNotImplemented() })
        }

        let isDelegate = interfaceOrDelegate.definition is DelegateDefinition
        if !isDelegate {
            // Delegates are IUnknown whereas interfaces are IInspectable
            let runtimeClassName = try WinRTTypeName.from(type: classDefinition?.bindType() ?? interfaceOrDelegate).description
            writer.writeStoredProperty(visibility: .public, static: true, declarator: .let, name: "runtimeClassName",
                initialValue: "\"\(runtimeClassName)\"")
        }

        // Classes derive from COMImport directly whereas interfaces and delegates are implemented using a nested class
        let implementationTypeName = classDefinition == nil ? "Implementation" : "Self"
        writer.writeFunc(
                visibility: .public, static: true, name: "toSwift",
                parameters: [ .init(label: "transferringRef", name: "comPointer", type: .identifier("COMPointer")) ],
                returnType: .identifier("SwiftObject")) { writer in
            writer.writeStatement("toSwift(transferringRef: comPointer, implementation: \(implementationTypeName).self)")
        }

        writer.writeFunc(
                visibility: .public, static: true, name: "toCOM",
                parameters: [ .init(label: "_", name: "object", escaping: isDelegate, type: .identifier("SwiftObject")) ],
                throws: true, returnType: .identifier("COMPointer")) { writer in
            if isDelegate {
                writer.writeStatement("let comExport = COMExport<Self>(implementation: object, queriableInterfaces: [ .init(Self.self) ])")
                writer.writeReturnStatement(value: "IUnknownPointer.addingRef(comExport.pointer)")
            }
            else {
                writer.writeStatement("try toCOM(object, implementation: \(implementationTypeName).self)")
            }
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

    internal func writeInterfaceImplementations(_ type: BoundType, to writer: SwiftTypeDefinitionWriter) throws {
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
            try writer.writeCommentLine(WinRTTypeName.from(type: interface.asBoundType).description)
            if interface == defaultInterface {
                try writeMemberImplementations(
                    interfaceOrDelegate: interface.asBoundType,
                    thisPointer: .name("comPointer"), to: writer)
            }
            else {
                let interfaceProperty = try writeSecondaryInterfaceProperty(interface, to: writer)
                try writeMemberImplementations(
                    interfaceOrDelegate: interface.asBoundType,
                    thisPointer: .getter(interfaceProperty.getter), to: writer)
                nonDefaultInterfaceStoredProperties.append(interfaceProperty.name)
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

    struct SecondaryInterfaceProperty {
        let name: String
        let getter: String
    }

    internal func writeSecondaryInterfaceProperty(
            _ interface: BoundInterface, staticOf: ClassDefinition? = nil,
            to writer: SwiftTypeDefinitionWriter) throws -> SecondaryInterfaceProperty {
        try writeSecondaryInterfaceProperty(
            interfaceName: projection.toTypeName(interface.definition, namespaced: false),
            abiName: CAbi.mangleName(type: interface.asBoundType),
            iid: WindowsMetadata.getInterfaceID(interface.asBoundType),
            staticOf: staticOf, to: writer)
    }

    internal func writeSecondaryInterfaceProperty(
            interfaceName: String, abiName: String, iid: UUID, staticOf: ClassDefinition? = nil,
            to writer: SwiftTypeDefinitionWriter) throws -> SecondaryInterfaceProperty {

        // private [static] var _istringable: UnsafeMutablePointer<__x_ABI_CIStringable>! = nil
        let storedPropertyName = "_" + Casing.pascalToCamel(interfaceName)
        let abiPointerType: SwiftType = .identifier("UnsafeMutablePointer", genericArgs: [.identifier(abiName)])
        writer.writeStoredProperty(visibility: .private, static: staticOf != nil, declarator: .var, name: storedPropertyName,
            type: .optional(wrapped: abiPointerType, implicitUnwrap: true),
            initialValue: "nil")

        // private [static] func _getIStringable() throws -> UnsafeMutablePointer<__x_ABI_CIStringable> {
        //     let iid = IID(00000035, 0000, 0000, C000, 000000000046)
        //     _istringable = try _istringable ?? WindowsRuntime.getActivationFactoryPointer(activatableId: "Windows.Foundation.IStringable", iid: iid)
        //     return _istringable
        // }
        let getter = "_get" + interfaceName
        try writer.writeFunc(visibility: .private, static: staticOf != nil, name: getter, throws: true, returnType: abiPointerType) {
            $0.writeStatement("let iid = \(try Self.toIIDExpression(iid))")
            if let staticOf {
                let activatableId = try WinRTTypeName.from(type: staticOf.bindType()).description
                $0.writeStatement("\(storedPropertyName) = try \(storedPropertyName) ?? WindowsRuntime.getActivationFactoryPointer("
                    + "activatableId: \"\(activatableId)\", iid: iid)")
            }
            else {
                $0.writeStatement("\(storedPropertyName) = try _queryInterfacePointer(iid).cast(to: \(abiName).self)")
            }
            $0.writeStatement("return \(storedPropertyName)")
        }

        return SecondaryInterfaceProperty(name: storedPropertyName, getter: getter)
    }
}