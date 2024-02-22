import CodeWriters
import Collections
import DotNetMetadata
import ProjectionModel
import WindowsMetadata
import struct Foundation.UUID

struct SecondaryInterfaceDeclaration {
    public let storedPropertyName: String
    public let lazyComputedPropertyName: String

    public var thisPointer: ThisPointer {
        .init(name: lazyComputedPropertyName, lazy: true)
    }
}

internal func writeSecondaryInterfaceDeclaration(
        _ interface: BoundInterface, staticOf: ClassDefinition? = nil,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws -> SecondaryInterfaceDeclaration {
    try writeSecondaryInterfaceDeclaration(
        interfaceName: projection.toTypeName(interface.definition, namespaced: false),
        abiName: CAbi.mangleName(type: interface.asBoundType),
        iid: WindowsMetadata.getInterfaceID(interface.asBoundType),
        staticOf: staticOf, projection: projection, to: writer)
}

internal func writeSecondaryInterfaceDeclaration(
        interfaceName: String, abiName: String, iid: UUID, staticOf: ClassDefinition? = nil,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws -> SecondaryInterfaceDeclaration {

    // private [static] var _istringable: COM.COMInterop<SWRT_WindowsFoundation_IStringable>? = nil
    let storedPropertyName = "_" + Casing.pascalToCamel(interfaceName)
    let abiStructType: SwiftType = .chain(projection.abiModuleName, abiName)
    let abiPointerType: SwiftType = .unsafeMutablePointer(to: abiStructType)
    let abiInteropType: SwiftType = SupportModule.comInterop(of: abiStructType)
    writer.writeStoredProperty(visibility: .private, static: staticOf != nil, declarator: .var, name: storedPropertyName,
        type: .optional(wrapped: abiInteropType),
        initialValue: "nil")

    // private [static] var _lazyIStringable: COM.COMInterop<SWRT_WindowsFoundation_IStringable> { get throws {
    //     if let existing = _istringable { return existing }
    //     let id = COM.COMInterop<SWRT_IStringable>.iid
    //     let new = try _queryInterfacePointer(id).cast(to: SWRT_WindowsFoundation_IStringable.self)
    //     _istringable = new
    //     return new
    // } }
    let lazyComputedPropertyName = getSecondaryInterfaceLazyComputedPropertyName(interfaceName)
    try writer.writeComputedProperty(
            visibility: .internal, static: staticOf != nil, name: lazyComputedPropertyName,
            type: abiInteropType, throws: true, get: { writer in
        writer.writeStatement("if let existing = \(storedPropertyName) { return existing }")
        if let staticOf {
            let activatableId = try WinRTTypeName.from(type: staticOf.bindType()).description
            writer.writeStatement("let new: \(abiPointerType) = try WindowsRuntime.getActivationFactoryPointer(\n"
                + "activatableId: \"\(activatableId)\", id: \(abiInteropType).iid)")
        }
        else {
            writer.writeStatement("let new = try _queryInterfacePointer(\(abiInteropType).iid).cast(to: \(abiName).self)")
        }
        writer.writeStatement("\(storedPropertyName) = .init(new)")
        writer.writeStatement("return .init(new)")
    })

    return .init(storedPropertyName: storedPropertyName, lazyComputedPropertyName: lazyComputedPropertyName)
}

internal func getSecondaryInterfaceLazyComputedPropertyName(_ interfaceDefinition: InterfaceDefinition) -> String {
    getSecondaryInterfaceLazyComputedPropertyName(interfaceDefinition.name)
}

fileprivate func getSecondaryInterfaceLazyComputedPropertyName(_ interfaceName: String) -> String {
    "_lazy" + interfaceName
}