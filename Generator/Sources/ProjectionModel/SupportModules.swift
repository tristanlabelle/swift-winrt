import CodeWriters
import DotNetMetadata
import WindowsMetadata

public enum SupportModules {
    public enum COM {}
    public enum WinRT {}
}

extension SupportModules.COM {
    public static var moduleName: String { "COM" }
    public static let moduleType: SwiftType = .named(moduleName)

    public static var abiModuleName: String { "COM_ABI" }

    public static var guid: SwiftType { moduleType.member("GUID") }

    public static var iunknownPointer: SwiftType { moduleType.member("IUnknownPointer") }
    public static var iunknownReference: SwiftType { moduleType.member("IUnknownReference") }
    public static var iunknownReference_Optional: SwiftType { iunknownReference.member("Optional") }
    public static var comInterfaceID: SwiftType { moduleType.member("COMInterfaceID") }
    public static var nullResult: SwiftType { moduleType.member("NullResult") }

    public static var hresult: SwiftType { moduleType.member("HResult") }

    public static var abiBinding: SwiftType { moduleType.member("ABIBinding") }
    public static var abiPODBinding: SwiftType { moduleType.member("PODBinding") }
    public static var boolBinding: SwiftType { moduleType.member("BoolBinding") }
    public static var wideCharBinding: SwiftType { moduleType.member("WideCharBinding") }
    public static var guidBinding: SwiftType { moduleType.member("GUIDBinding") }
    public static var hresultBinding: SwiftType { moduleType.member("HResultBinding") }

    public static var comBinding: SwiftType { moduleType.member("COMBinding") }
    public static var comTwoWayBinding: SwiftType { moduleType.member("COMTwoWayBinding") }

    public static var comEmbedding: SwiftType { moduleType.member("COMEmbedding") }

    public static var comReference: SwiftType { moduleType.member("COMReference") }
    public static func comReference(to type: SwiftType) -> SwiftType {
        moduleType.member("COMReference", genericArgs: [type])
    }

    public static var comReference_Optional: SwiftType { moduleType.member("COMReference.Optional") }
    public static func comReference_Optional(to type: SwiftType) -> SwiftType {
        comReference(to: type).member("Optional")
    }

    public static var comReference_Optional_lazyInitInterop: String { "lazyInitInterop" }
    public static var comReference_Optional_lazyInitPointer: String { "lazyInitPointer" }

    public static var comInterop: SwiftType { moduleType.member("COMInterop") }
    public static func comInterop(of type: SwiftType) -> SwiftType {
        moduleType.member("COMInterop", genericArgs: [type])
    }

    public static func comArray(of type: SwiftType) -> SwiftType {
        moduleType.member("COMArray", genericArgs: [type])
    }
}

extension SupportModules.WinRT {
    public static var moduleName: String { "WindowsRuntime" }
    public static let moduleType: SwiftType = .named(moduleName)

    public static var abiModuleName: String { "WindowsRuntime_ABI" }

    public static var char16: SwiftType { moduleType.member("Char16") }

    public static var eventRegistration: SwiftType { moduleType.member("EventRegistration") }
    public static var eventRegistrationToken: SwiftType { moduleType.member("EventRegistrationToken") }
    public static var iinspectable: SwiftType { moduleType.member("IInspectable") }
    public static var iinspectablePointer: SwiftType { moduleType.member("IInspectablePointer") }
    public static var iinspectableBinding: SwiftType { moduleType.member("IInspectableBinding") }

    public static var openEnumBinding: SwiftType { moduleType.member("OpenEnumBinding") }
    public static var closedEnumBinding: SwiftType { moduleType.member("ClosedEnumBinding") }
    public static var structBinding: SwiftType { moduleType.member("StructBinding") }
    public static var interfaceBinding: SwiftType { moduleType.member("InterfaceBinding") }
    public static var delegateBinding: SwiftType { moduleType.member("DelegateBinding") }
    public static var runtimeClassBinding: SwiftType { moduleType.member("RuntimeClassBinding") }
    public static var composableClassBinding: SwiftType { moduleType.member("ComposableClassBinding") }

    public static var composableClass: SwiftType { moduleType.member("ComposableClass") }
    public static var composableClass_outerObject: SwiftType { composableClass.member("OuterObject") }
    public static var composableClass_outerObject_shortName: String { "OuterObject" }
    public static var composableClass_supportsOverrides: String { "supportsOverrides" }

    public static func winRTImport(of type: SwiftType) -> SwiftType {
        moduleType.member("WinRTImport", genericArgs: [type])
    }

    public static func arrayBinding(of type: SwiftType) -> SwiftType {
        moduleType.member("ArrayBinding", genericArgs: [type])
    }

    public static func primitiveBinding(of type: WinRTPrimitiveType) -> SwiftType {
        moduleType.member(type.name + "Binding")
    }

    public static func ireferenceToOptionalBinding(of type: WinRTPrimitiveType) -> SwiftType {
        moduleType.member(type.name + "Binding").member("IReferenceToOptional")
    }

    public static func ireferenceToOptionalBinding(of bindingType: SwiftType) -> SwiftType {
        moduleType.member("IReferenceToOptionalBinding", genericArgs: [ bindingType ])
    }

    public static var iactivationFactoryBinding: SwiftType { moduleType.member("IActivationFactoryBinding") }

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