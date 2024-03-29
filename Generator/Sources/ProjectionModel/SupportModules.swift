import CodeWriters
import DotNetMetadata
import WindowsMetadata

public enum SupportModules {
    public enum COM {}
    public enum WinRT {}
}

extension SupportModules.COM {
    public static var moduleName: String { "COM" }

    public static var implementABIMethodFunc: String { "\(moduleName).implementABIMethod" }

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
    public static var winRTClassProjection: SwiftType { .chain(moduleName, "WinRTClassProjection") }

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

extension SupportModules.WinRT {
    public static func hasBuiltInProjection(_ typeDefinition: TypeDefinition) -> Bool {
        if typeDefinition.namespace == "Windows.Foundation" {
            switch typeDefinition.name {
                case "EventRegistrationToken", "HResult", "IReference`1": return true
                default: return false
            }
        }
        return false
    }
}