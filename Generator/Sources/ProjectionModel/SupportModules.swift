import CodeWriters
import DotNetMetadata
import WindowsMetadata

public enum SupportModules {
    public enum COM {}
    public enum WinRT {}
}

extension SupportModules.COM {
    public static var moduleName: String { "COM" }
    public static var abiModuleName: String { "COM_ABI" }

    public static var guid: SwiftType { .chain(moduleName, "GUID") }

    public static var iunknownPointer: SwiftType { .chain(moduleName, "IUnknownPointer") }
    public static var iunknownReference: SwiftType { .chain(moduleName, "IUnknownReference") }
    public static var iunknownReference_Optional: SwiftType { .chain(moduleName, "IUnknownReference", "Optional") }
    public static var comInterfaceID: SwiftType { .chain(moduleName, "COMInterfaceID") }
    public static var nullResult: SwiftType { .chain(moduleName, "NullResult") }

    public static var hresult: SwiftType { .chain(moduleName, "HResult") }

    public static var abiBinding: SwiftType { .chain(moduleName, "ABIBinding") }
    public static var abiPODBinding: SwiftType { .chain(moduleName, "PODBinding") }
    public static var boolBinding: SwiftType { .chain(moduleName, "BoolBinding") }
    public static var wideCharBinding: SwiftType { .chain(moduleName, "WideCharBinding") }
    public static var guidBinding: SwiftType { .chain(moduleName, "GUIDBinding") }
    public static var hresultBinding: SwiftType { .chain(moduleName, "HResultBinding") }

    public static var comBinding: SwiftType { .chain(moduleName, "COMBinding") }
    public static var comTwoWayBinding: SwiftType { .chain(moduleName, "COMTwoWayBinding") }

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
    public static var abiModuleName: String { "WindowsRuntime_ABI" }

    public static var char16: SwiftType { .chain(moduleName, "Char16") }

    public static var eventRegistration: SwiftType { .chain(moduleName, "EventRegistration") }
    public static var eventRegistrationToken: SwiftType { .chain(moduleName, "EventRegistrationToken") }
    public static var iinspectable: SwiftType { .chain(moduleName, "IInspectable") }
    public static var iinspectablePointer: SwiftType { .chain(moduleName, "IInspectablePointer") }
    public static var iinspectableBinding: SwiftType { .chain(moduleName, "IInspectableBinding") }

    public static var openEnumBinding: SwiftType { .chain(moduleName, "OpenEnumBinding") }
    public static var closedEnumBinding: SwiftType { .chain(moduleName, "ClosedEnumBinding") }
    public static var structBinding: SwiftType { .chain(moduleName, "StructBinding") }
    public static var interfaceBinding: SwiftType { .chain(moduleName, "InterfaceBinding") }
    public static var delegateBinding: SwiftType { .chain(moduleName, "DelegateBinding") }
    public static var activatableClassBinding: SwiftType { .chain(moduleName, "ActivatableClassBinding") }
    public static var composableClassBinding: SwiftType { .chain(moduleName, "ComposableClassBinding") }

    public static var composableClass: SwiftType { .chain(moduleName, "ComposableClass") }

    public static func winRTImport(of type: SwiftType) -> SwiftType {
        .chain([ .init(moduleName), .init("WinRTImport", genericArgs: [type]) ])
    }

    public static func arrayBinding(of type: SwiftType) -> SwiftType {
        .chain([ .init(moduleName), .init("ArrayBinding", genericArgs: [type]) ])
    }

    public static func primitiveBinding(of type: WinRTPrimitiveType) -> SwiftType {
        .chain([ .init(moduleName), .init(type.name + "Binding") ])
    }

    public static func ireferenceToOptionalBinding(of type: WinRTPrimitiveType) -> SwiftType {
        .chain([ .init(moduleName), .init(type.name + "Binding"), .init("IReferenceToOptional") ])
    }

    public static func ireferenceToOptionalBinding(of bindingType: SwiftType) -> SwiftType {
        .chain([ .init(moduleName), .init("IReferenceToOptionalBinding", genericArgs: [ bindingType ]) ])
    }

    public static var iactivationFactoryBinding: SwiftType { .chain(moduleName, "IActivationFactoryBinding") }

    public static var activationFactoryResolverGlobal: String { "\(moduleName).activationFactoryResolver" }
    public static var swiftWrapperFactoryGlobal: String { "\(moduleName).swiftWrapperFactory" }
}

public enum BuiltInTypeKind {
    /// Indicates that the support module has special support for this type,
    /// and no definition or binding should be generated.
    case special
    /// Indicates that the support module exposes a definition for this type, but no binding.
    case definitionOnly
    /// Indicates that the support module exposes both a definition and a binding for this type.
    case definitionAndBinding
}

extension SupportModules.WinRT {
    private enum BuiltInTypes {
        internal static let windowsFoundation: Dictionary<String, BuiltInTypeKind> = [
            "DateTime": .definitionAndBinding,
            "EventRegistrationToken": .special,
            "HResult": .special,
            "IPropertyValue": .definitionOnly,
            "IReference`1": .definitionAndBinding,
            "IReferenceArray`1": .definitionAndBinding,
            "IStringable": .definitionAndBinding,
            "Point": .definitionAndBinding,
            "PropertyType": .definitionAndBinding,
            "Rect": .definitionAndBinding,
            "Size": .definitionAndBinding,
            "TimeSpan": .definitionAndBinding
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