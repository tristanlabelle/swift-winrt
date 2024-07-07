import CodeWriters
import DotNetMetadata
import WindowsMetadata

public enum SupportModules {
    public enum COM {}
    public enum WinRT {}
}

extension SupportModules.COM {
    public static var moduleName: String { "COM" }

    public static var guid: SwiftType { .chain(moduleName, "GUID") }

    public static var iunknownPointer: SwiftType { .chain(moduleName, "IUnknownPointer") }
    public static var comInterfaceID: SwiftType { .chain(moduleName, "COMInterfaceID") }
    public static var nullResult: SwiftType { .chain(moduleName, "NullResult") }

    public static var hresult: SwiftType { .chain(moduleName, "HResult") }

    public static var abiProjection: SwiftType { .chain(moduleName, "ABIProjection") }
    public static var abiInertProjection: SwiftType { .chain(moduleName, "ABIInertProjection") }
    public static var boolProjection: SwiftType { .chain(moduleName, "BoolProjection") }
    public static var wideCharProjection: SwiftType { .chain(moduleName, "WideCharProjection") }
    public static var guidProjection: SwiftType { .chain(moduleName, "GUIDProjection") }
    public static var hresultProjection: SwiftType { .chain(moduleName, "HResultProjection") }

    public static var comProjection: SwiftType { .chain(moduleName, "COMProjection") }
    public static var comTwoWayProjection: SwiftType { .chain(moduleName, "COMTwoWayProjection") }

    public static var comEmbedding: SwiftType { .chain(moduleName, "COMEmbedding") }

    public static var comReference: SwiftType { .chain(moduleName, "COMReference") }
    public static func comReference(to type: SwiftType) -> SwiftType {
        .chain([ .init(moduleName), .init("COMReference", genericArgs: [type]) ])
    }

    public static var comReference_Optional: SwiftType { .chain(moduleName, "COMReference.Optional") }
    public static func comReference_Optional(to type: SwiftType) -> SwiftType {
        .chain([ .init(moduleName), .init("COMReference", genericArgs: [type]), .init("Optional") ])
    }

    public static var comReference_Optional_lazyInitInterop: String { "lazyInitInterop" }
    public static var comReference_Optional_lazyInitPointer: String { "lazyInitPointer" }

    public static var comInterop: SwiftType { .chain(moduleName, "COMInterop") }
    public static func comInterop(of type: SwiftType) -> SwiftType {
        .chain([ .init(moduleName), .init("COMInterop", genericArgs: [type]) ])
    }

    public static func comArray(of type: SwiftType) -> SwiftType {
        .chain([ .init(moduleName), .init("COMArray", genericArgs: [type]) ])
    }
}

extension SupportModules.WinRT {
    public static var moduleName: String { "WindowsRuntime" }

    public static var char16: SwiftType { .chain(moduleName, "Char16") }

    public static var eventRegistration: SwiftType { .chain(moduleName, "EventRegistration") }
    public static var eventRegistrationToken: SwiftType { .chain(moduleName, "EventRegistrationToken") }
    public static var iinspectable: SwiftType { .chain(moduleName, "IInspectable") }
    public static var iinspectablePointer: SwiftType { .chain(moduleName, "IInspectablePointer") }
    public static var iinspectableProjection: SwiftType { .chain(moduleName, "IInspectableProjection") }

    public static var enumProjection: SwiftType { .chain(moduleName, "EnumProjection") }
    public static var structProjection: SwiftType { .chain(moduleName, "StructProjection") }
    public static var interfaceProjection: SwiftType { .chain(moduleName, "InterfaceProjection") }
    public static var delegateProjection: SwiftType { .chain(moduleName, "DelegateProjection") }
    public static var activatableClassProjection: SwiftType { .chain(moduleName, "ActivatableClassProjection") }
    public static var composableClassProjection: SwiftType { .chain(moduleName, "ComposableClassProjection") }

    public static var composableClass: SwiftType { .chain(moduleName, "ComposableClass") }

    public static func winRTImport(of type: SwiftType) -> SwiftType {
        .chain([ .init(moduleName), .init("WinRTImport", genericArgs: [type]) ])
    }

    public static func arrayProjection(of type: SwiftType) -> SwiftType {
        .chain([ .init(moduleName), .init("ArrayProjection", genericArgs: [type]) ])
    }

    public static func primitiveProjection(of type: WinRTPrimitiveType) -> SwiftType {
        .chain([ .init(moduleName), .init("PrimitiveProjection"), .init(type.name) ])
    }

    public static func ireferenceUnboxingProjection(of type: WinRTPrimitiveType) -> SwiftType {
        .chain([ .init(moduleName), .init("IReferenceUnboxingProjection"), .init(type.name) ])
    }

    public static func ireferenceUnboxingProjection(of projectionType: SwiftType) -> SwiftType {
        .chain([ .init(moduleName), .init("IReferenceUnboxingProjection"), .init("Of", genericArgs: [ projectionType ]) ])
    }

    public static var iactivationFactoryProjection: SwiftType { .chain(moduleName, "IActivationFactoryProjection") }

    public static var activationFactoryResolverGlobal: String { "\(moduleName).activationFactoryResolver" }
    public static var swiftWrapperFactoryGlobal: String { "\(moduleName).swiftWrapperFactory" }
}

public enum BuiltInTypeKind {
    /// Indicates that the support module has special support for this type,
    /// and no definition or projection should be generated.
    case special
    /// Indicates that the support module exposes a definition for this type, but no projection.
    case definitionOnly
    /// Indicates that the support module exposes both a definition and a projection for this type.
    case definitionAndProjection
}

extension SupportModules.WinRT {
    private enum BuiltInTypes {
        internal static let windowsFoundation: Dictionary<String, BuiltInTypeKind> = [
            "DateTime": .definitionAndProjection,
            "EventRegistrationToken": .special,
            "HResult": .special,
            "IPropertyValue": .definitionOnly,
            "IReference`1": .definitionAndProjection,
            "IStringable": .definitionAndProjection,
            "Point": .definitionAndProjection,
            "PropertyType": .definitionAndProjection,
            "Rect": .definitionAndProjection,
            "Size": .definitionAndProjection,
            "TimeSpan": .definitionAndProjection
        ]
    }

    public static func getBuiltInTypeKind(_ typeDefinition: TypeDefinition) -> BuiltInTypeKind? {
        switch typeDefinition.namespace {
            case "Windows.Foundation":
                return BuiltInTypes.windowsFoundation[typeDefinition.name]
            default: return nil
        }
    }
}