import CodeWriters
import Collections
import DotNetMetadata
import ProjectionGenerator
import WindowsMetadata
import struct Foundation.UUID

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
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws -> SecondaryInterfaceProperty {
    try writeSecondaryInterfaceProperty(
        interfaceName: projection.toTypeName(interface.definition, namespaced: false),
        abiName: CAbi.mangleName(type: interface.asBoundType),
        iid: WindowsMetadata.getInterfaceID(interface.asBoundType),
        staticOf: staticOf, projection: projection, to: writer)
}

internal func writeSecondaryInterfaceProperty(
        interfaceName: String, abiName: String, iid: UUID, staticOf: ClassDefinition? = nil,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws -> SecondaryInterfaceProperty {

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