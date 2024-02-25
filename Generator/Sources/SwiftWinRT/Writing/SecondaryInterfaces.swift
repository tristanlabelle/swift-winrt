import CodeWriters
import Collections
import DotNetMetadata
import ProjectionModel
import WindowsMetadata
import struct Foundation.UUID

internal enum SecondaryInterfaces {
    internal static func writeDeclaration(
            _ interface: BoundInterface, staticOf: ClassDefinition? = nil, composable: Bool = false,
            projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
        try writeDeclaration(
            interfaceName: projection.toTypeName(interface.definition, namespaced: false),
            abiStructType: projection.toABIType(interface.asBoundType),
            staticOf: staticOf, composable: composable,
            projection: projection, to: writer)
    }

    internal static func writeDeclaration(
            interfaceName: String, abiStructType: SwiftType, staticOf: ClassDefinition? = nil, composable: Bool = false,
            projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {

        // private [static] var _istringable_storage: COM.COMInterop<SWRT_WindowsFoundation_IStringable>? = nil
        let storedPropertyName = getStoredPropertyName(interfaceName)
        let abiInteropType: SwiftType = SupportModule.comInterop(of: abiStructType)
        writer.writeStoredProperty(visibility: .private, static: staticOf != nil, declarator: .var, name: storedPropertyName,
            type: .optional(wrapped: abiInteropType),
            initialValue: "nil")

        // private [static] var _istringable: COM.COMInterop<SWRT_WindowsFoundation_IStringable> { get throws {
        //     try _istringable_storage.lazyInit { try _queryInterfacePointer(SWRT_IStringable.iid) }
        // } }
        let computedPropertyName = getPropertyName(interfaceName: interfaceName)
        try writer.writeComputedProperty(
                visibility: .internal, static: staticOf != nil, name: computedPropertyName,
                type: abiInteropType, throws: true, get: { writer in
            try writer.writeBracedBlock("try \(storedPropertyName).\(SupportModule.comInteropLazyInitFunc)") { writer in
                if let staticOf {
                    let activatableId = try WinRTTypeName.from(type: staticOf.bindType()).description
                    writer.writeStatement("try WindowsRuntime.getActivationFactoryPointer("
                        + "activatableId: \"\(activatableId)\", id: \(abiStructType).iid)")
                }
                else {
                    let qiMethodName = composable ? "_queryInnerInterfacePointer" : "_queryInterfacePointer"
                    writer.writeStatement("try \(qiMethodName)(\(abiStructType).iid).cast(to: \(abiStructType).self)")
                }
            }
        })
    }

    internal static func getPropertyName(_ interface: BoundInterface, suffix: String? = nil) -> String {
        getPropertyName(interfaceName: interface.definition.nameWithoutGenericSuffix, suffix: suffix)
    }

    internal static func getPropertyName(interfaceName: String, suffix: String? = nil) -> String {
        var name = "_" + Casing.pascalToCamel(interfaceName)
        if let suffix { name += "_" + suffix }
        return name
    }

    internal static func getOverridableOuterName(_ interface: BoundInterface) -> String {
        getPropertyName(interface) + "_outer"
    }

    internal static func writeCleanup(_ interface: BoundInterface, to writer: SwiftStatementWriter) {
        writeCleanup(interface.definition.nameWithoutGenericSuffix, to: writer)
    }

    internal static func writeCleanup(_ interfaceName: String, to writer: SwiftStatementWriter) {
        let storedPropertyName = getStoredPropertyName(interfaceName)
        writer.writeStatement("\(storedPropertyName)?.release()")
    }

    fileprivate static func getStoredPropertyName(_ interfaceName: String) -> String {
        getPropertyName(interfaceName: interfaceName) + "_storage"
    }
}