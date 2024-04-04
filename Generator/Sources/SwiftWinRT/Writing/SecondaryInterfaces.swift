import CodeWriters
import Collections
import DotNetMetadata
import ProjectionModel
import WindowsMetadata

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

        // private [static] var _lazyIStringable: COM.COMLazyReference<SWRT_WindowsFoundation_IStringable> = .init()
        let storedPropertyName = getStoredPropertyName(interfaceName)
        writer.writeStoredProperty(visibility: .private, static: staticOf != nil, declarator: .var, name: storedPropertyName,
            type: SupportModules.COM.comLazyReference(to: abiStructType), initialValue: ".init()")

        // private [static] var _istringable: COM.COMInterop<SWRT_WindowsFoundation_IStringable> { get throws {
        //     try _lazyIStringable.getInterop { try _queryInterface(SWRT_IStringable.iid).reinterpret() }
        // } }
        let computedPropertyName = getPropertyName(interfaceName: interfaceName)
        let abiInteropType: SwiftType = SupportModules.COM.comInterop(of: abiStructType)
        try writer.writeComputedProperty(
                visibility: .internal, static: staticOf != nil, name: computedPropertyName,
                type: abiInteropType, throws: true, get: { writer in
            try writer.writeBracedBlock("try \(storedPropertyName).\(SupportModules.COM.comLazyReference_getInterop)") { writer in
                if let staticOf {
                    let activatableId = try WinRTTypeName.from(type: staticOf.bindType()).description
                    if interfaceName == "IActivationFactory" {
                        // Workaround a compiler bug where the compiler doesn't see the SWRT_IActivationFactory extension.
                        writer.writeStatement("try \(metaclassResolverGlobalName).getActivationFactory(runtimeClass: \"\(activatableId)\")")
                    } else {
                        writer.writeStatement("try \(metaclassResolverGlobalName).getActivationFactory(\n"
                            + "runtimeClass: \"\(activatableId)\", interfaceID: \(abiStructType).iid)")
                    }
                }
                else {
                    let qiMethodName = composable ? "_queryInnerInterface" : "_queryInterface"
                    writer.writeStatement("try \(qiMethodName)(\(abiStructType).iid).reinterpret()")
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
        "_outer" + interface.definition.nameWithoutGenericSuffix
    }

    fileprivate static func getStoredPropertyName(_ interfaceName: String) -> String {
        "_lazy" + interfaceName
    }
}