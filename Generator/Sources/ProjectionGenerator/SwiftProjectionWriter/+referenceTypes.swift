import CodeWriters
import Collections
import DotNetMetadata
import WindowsMetadata
import struct Foundation.UUID

extension SwiftProjectionWriter {
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

    /// Writes members implementing the COMProjection or WinRTProjection protocol
    internal func writeCOMProjectionConformance(
            apiType: BoundType, abiType: BoundType,
            toSwiftBody: (_ writer: inout SwiftStatementWriter, _ paramName: String) throws -> Void,
            toCOMBody: (_ writer: inout SwiftStatementWriter, _ paramName: String) throws -> Void,
            to writer: SwiftTypeDefinitionWriter) throws {
        let abiName = try CAbi.mangleName(type: abiType)

        writer.writeTypeAlias(visibility: .public, name: "SwiftObject",
            target: try projection.toType(apiType.asNode).unwrapOptional())
        writer.writeTypeAlias(visibility: .public, name: "COMInterface",
            target: .chain(projection.abiModuleName, abiName))
        writer.writeTypeAlias(visibility: .public, name: "COMVirtualTable",
            target: .chain(projection.abiModuleName, abiName + CAbi.virtualTableSuffix))

        // public static var id: COM.COMInterfaceID { COM.COMInterop<COMInterface>.iid }
        writer.writeComputedProperty(visibility: .public, static: true, name: "id", type: .chain("COM", "COMInterfaceID")) { writer in
            writer.writeStatement("COM.COMInterop<COMInterface>.iid")
        }

        if !(abiType.definition is DelegateDefinition) {
            // Delegates are IUnknown whereas interfaces are IInspectable
            let runtimeClassName = try WinRTTypeName.from(type: apiType).description
            writer.writeStoredProperty(visibility: .public, static: true, declarator: .let, name: "runtimeClassName",
                initialValue: "\"\(runtimeClassName)\"")
        }

        try writer.writeFunc(
                visibility: .public, static: true, name: "toSwift",
                params: [ .init(label: "transferringRef", name: "comPointer", type: .identifier("COMPointer")) ],
                returnType: .identifier("SwiftObject")) { writer in
            try toSwiftBody(&writer, "comPointer")
        }

        try writer.writeFunc(
                visibility: .public, static: true, name: "toCOM",
                params: [ .init(label: "_", name: "object", escaping: abiType.definition is DelegateDefinition, type: .identifier("SwiftObject")) ],
                throws: true, returnType: .identifier("COMPointer")) { writer in
            try toCOMBody(&writer, "object")
        }
    }

    internal func getAllInterfaces(_ type: BoundType) throws -> [BoundInterface] {
        var interfaces = [BoundInterface]()

        func visit(_ interface: BoundInterface) throws {
            guard !interfaces.contains(interface) else { return }
            interfaces.append(interface)

            for baseInterface in interface.definition.baseInterfaces {
                try visit(baseInterface.interface.bindGenericParams(
                    typeArgs: interface.genericArgs))
            }
        }

        if let interfaceDefinition = type.definition as? InterfaceDefinition {
            try visit(interfaceDefinition.bind(genericArgs: type.genericArgs))
        }
        else {
            for baseInterface in type.definition.baseInterfaces {
                try visit(try baseInterface.interface.bindGenericParams(typeArgs: type.genericArgs))
            }
        }

        return interfaces
    }

    internal func getAllBaseInterfaces(_ type: BoundType) throws -> [BoundInterface] {
        var interfaces = [BoundInterface]()

        func visit(_ interface: BoundInterface) throws {
            guard !interfaces.contains(interface) else { return }
            interfaces.append(interface)

            for baseInterface in interface.definition.baseInterfaces {
                try visit(baseInterface.interface.bindGenericParams(typeArgs: interface.genericArgs))
            }
        }

        for baseInterface in type.definition.baseInterfaces {
            try visit(try baseInterface.interface.bindGenericParams(typeArgs: type.genericArgs))
        }

        return interfaces
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

        // private [static] var _istringable: UnsafeMutablePointer<SWRT_WindowsFoundation_IStringable>? = nil
        let storedPropertyName = "_" + Casing.pascalToCamel(interfaceName)
        let abiStructType: SwiftType = .chain(projection.abiModuleName, abiName)
        let abiPointerType: SwiftType = .unsafeMutablePointer(to: abiStructType)
        writer.writeStoredProperty(visibility: .private, static: staticOf != nil, declarator: .var, name: storedPropertyName,
            type: .optional(wrapped: abiPointerType),
            initialValue: "nil")

        // private [static] func _getIStringable() throws -> UnsafeMutablePointer<SWRT_WindowsFoundation_IStringable> {
        //     if let existing = _istringable { return existing }
        //     let id = COM.COMInterop<SWRT_IStringable>.iid
        //     let new = try _queryInterfacePointer(id).cast(to: SWRT_WindowsFoundation_IStringable.self)
        //     _istringable = new
        //     return new
        // }
        let getter = "_get" + interfaceName
        try writer.writeFunc(visibility: .fileprivate, static: staticOf != nil, name: getter, throws: true, returnType: abiPointerType) {
            $0.writeStatement("if let existing = \(storedPropertyName) { return existing }")
            $0.writeStatement("let id = COM.COMInterop<\(abiStructType)>.iid")
            if let staticOf {
                let activatableId = try WinRTTypeName.from(type: staticOf.bindType()).description
                $0.writeStatement("let new: \(abiPointerType) = try WindowsRuntime.getActivationFactoryPointer(\n"
                    + "activatableId: \"\(activatableId)\", id: id)")
            }
            else {
                $0.writeStatement("let new = try _queryInterfacePointer(id).cast(to: \(abiName).self)")
            }
            $0.writeStatement("\(storedPropertyName) = new")
            $0.writeStatement("return new")
        }

        return SecondaryInterfaceProperty(name: storedPropertyName, getter: getter)
    }
}