import CodeWriters
import Collections
import DotNetMetadata
import ProjectionModel
import WindowsMetadata

internal enum SecondaryInterfaces {
    internal static func writeDeclaration(
            _ interface: BoundInterface, static: Bool, composable: Bool = false,
            projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
        let interfaceName = try projection.toTypeName(interface.definition, namespaced: false)
        let abiStructType = try projection.toABIType(interface.asBoundType)

        // private [static] var _lazyIStringable: COM.COMReference<SWRT_WindowsFoundation_IStringable>.Optional = .none
        let storedPropertyName = getStoredPropertyName(interfaceName)
        writer.writeStoredProperty(visibility: .private, static: `static`, declarator: .var, name: storedPropertyName,
            type: SupportModules.COM.comReference_Optional(to: abiStructType), initialValue: ".none")

        // private [static] var _istringable: COM.COMInterop<SWRT_WindowsFoundation_IStringable> { get throws {
        //     try _lazyIStringable.lazyInitInterop { try _queryInterface(uuidof(SWRT_IStringable).self).cast() }
        // } }
        let computedPropertyName = getPropertyName(interfaceName: interfaceName)
        let abiInteropType: SwiftType = SupportModules.COM.comInterop(of: abiStructType)
        writer.writeComputedProperty(
                visibility: .internal, static: `static`, name: computedPropertyName,
                type: abiInteropType, throws: true, get: { writer in
            writer.writeBracedBlock("try \(storedPropertyName).\(SupportModules.COM.comReference_Optional_lazyInitInterop)") { writer in
                let queryInterface: String
                if `static` {
                    queryInterface = "\(activationFactoryPropertyName).queryInterface"
                } else if composable {
                    queryInterface = "_queryInnerInterface"
                } else {
                    queryInterface = "_queryInterface"
                }
                writer.writeStatement("try \(queryInterface)(uuidof(\(abiStructType).self)).cast()")
            }
        })
    }

    internal static let activationFactoryPropertyName = "_iactivationFactory"

    internal static func writeActivationFactoryDeclaration(
            classDefinition: ClassDefinition, projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
        let storedPropertyName = "_lazyIActivationFactory"
        let abiStructType = SwiftType.identifier("SWRT_IActivationFactory")

        writer.writeStoredProperty(
            visibility: .private, static: true, declarator: .var, name: storedPropertyName,
            type: SupportModules.COM.comReference_Optional(to: abiStructType),
            initialValue: ".init()")
         try writer.writeComputedProperty(
                visibility: .private, static: true, name: activationFactoryPropertyName,
                type: SupportModules.COM.comInterop(of: abiStructType), throws: true, get: { writer in
            try writer.writeBracedBlock("try \(storedPropertyName).\(SupportModules.COM.comReference_Optional_lazyInitInterop)") { writer in
                let activatableId = try WinRTTypeName.from(type: classDefinition.bindType()).description
                writer.writeStatement("try \(SupportModules.WinRT.activationFactoryResolverGlobal)"
                    + ".resolve(runtimeClass: \"\(activatableId)\")")
            }
        })
    }

    internal static func getPropertyName(_ interface: BoundInterface, suffix: String? = nil) -> String {
        getPropertyName(interfaceName: interface.definition.nameWithoutGenericArity, suffix: suffix)
    }

    internal static func getPropertyName(interfaceName: String, suffix: String? = nil) -> String {
        var name = "_" + Casing.pascalToCamel(interfaceName)
        if let suffix { name += "_" + suffix }
        return name
    }

    internal static func getOverridableOuterName(_ interface: BoundInterface) -> String {
        "_outer" + interface.definition.nameWithoutGenericArity
    }

    fileprivate static func getStoredPropertyName(_ interfaceName: String) -> String {
        "_lazy" + interfaceName
    }
}