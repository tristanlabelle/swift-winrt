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
    public static var comIUnknownStruct: SwiftType { .chain(moduleName, "COMIUnknownStruct") }
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

    public static var comExportedInterface: SwiftType { .chain(moduleName, "COMExportedInterface") }

    public static var comReference: SwiftType { .chain(moduleName, "COMReference") }
    public static func comReference(to type: SwiftType) -> SwiftType {
        .chain([ .init(moduleName), .init("COMReference", genericArgs: [type]) ])
    }

    public static var comLazyReference: SwiftType { .chain(moduleName, "COMLazyReference") }
    public static func comLazyReference(to type: SwiftType) -> SwiftType {
        .chain([ .init(moduleName), .init("COMLazyReference", genericArgs: [type]) ])
    }

    public static var comLazyReference_getInterop: String { "getInterop" }
    public static var comLazyReference_getPointer: String { "getPointer" }

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

    public static var comIInspectableStruct: SwiftType { .chain(moduleName, "COMIInspectableStruct") }
    public static var eventRegistration: SwiftType { .chain(moduleName, "EventRegistration") }
    public static var eventRegistrationToken: SwiftType { .chain(moduleName, "EventRegistrationToken") }
    public static var iinspectable: SwiftType { .chain(moduleName, "IInspectable") }
    public static var iinspectablePointer: SwiftType { .chain(moduleName, "IInspectablePointer") }
    public static var iinspectableProjection: SwiftType { .chain(moduleName, "IInspectableProjection") }

    public static var winRTEnumProjection: SwiftType { .chain(moduleName, "WinRTEnumProjection") }
    public static var winRTStructProjection: SwiftType { .chain(moduleName, "WinRTStructProjection") }
    public static var winRTInterfaceProjection: SwiftType { .chain(moduleName, "WinRTInterfaceProjection") }
    public static var winRTDelegateProjection: SwiftType { .chain(moduleName, "WinRTDelegateProjection") }
    public static var winRTActivatableClassProjection: SwiftType { .chain(moduleName, "WinRTActivatableClassProjection") }
    public static var winRTComposableClassProjection: SwiftType { .chain(moduleName, "WinRTComposableClassProjection") }

    public static var winRTComposableClass: SwiftType { .chain(moduleName, "WinRTComposableClass") }

    public static func winRTImport(of type: SwiftType) -> SwiftType {
        .chain([ .init(moduleName), .init("WinRTImport", genericArgs: [type]) ])
    }

    public static func winRTArrayProjection(of type: SwiftType) -> SwiftType {
        .chain([ .init(moduleName), .init("WinRTArrayProjection", genericArgs: [type]) ])
    }

    public static func winRTPrimitiveProjection(of type: WinRTPrimitiveType) -> SwiftType {
        .chain([ .init(moduleName), .init("WinRTPrimitiveProjection"), .init(type.name) ])
    }

    public static func ireferenceUnboxingProjection(of type: WinRTPrimitiveType) -> SwiftType {
        .chain([ .init(moduleName), .init("IReferenceUnboxingProjection"), .init(type.name) ])
    }

    public static func ireferenceUnboxingProjection(of projectionType: SwiftType) -> SwiftType {
        .chain([ .init(moduleName), .init("IReferenceUnboxingProjection"), .init("Of", genericArgs: [ projectionType ]) ])
    }

    public static var winRTClassLoader: SwiftType { .chain(moduleName, "WinRTClassLoader") }
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
            "DateTime": .definitionOnly,
            "EventRegistrationToken": .special,
            "HResult": .special,
            "IPropertyValue": .definitionOnly,
            "IReference`1": .definitionAndProjection,
            "IStringable": .definitionAndProjection,
            "Point": .definitionOnly,
            "PropertyType": .definitionOnly,
            "Rect": .definitionOnly,
            "Size": .definitionOnly,
            "TimeSpan": .definitionOnly
        ]
        internal static let windowsFoundationCollections = [
            "IIterable`1",
            "IIterator`1"
        ]
    }

    public static func getBuiltInTypeKind(_ typeDefinition: TypeDefinition) -> BuiltInTypeKind? {
        switch typeDefinition.namespace {
            case "Windows.Foundation":
                return BuiltInTypes.windowsFoundation[typeDefinition.name]
            case "Windows.Foundation.Collections":
                return BuiltInTypes.windowsFoundationCollections.contains(typeDefinition.name) ? .definitionOnly : nil
            default: return nil
        }
    }
}