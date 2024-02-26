import CodeWriters
import DotNetMetadata

public enum SupportModule {
    public static var comModuleName: String { "COM" }

    public static var implementABIMethodFunc: String { "\(comModuleName).implementABIMethod" }

    public static var iunknownPointer: SwiftType { .chain(comModuleName, "IUnknownPointer") }
    public static var comInterfaceID: SwiftType { .chain(comModuleName, "COMInterfaceID") }
    public static var comIUnknownStruct: SwiftType { .chain(winrtModuleName, "COMIUnknownStruct") }
    public static var nullResult: SwiftType { .chain(comModuleName, "NullResult") }

    public static var hresult: SwiftType { .chain(comModuleName, "HResult") }

    public static var abiProjection: SwiftType { .chain(comModuleName, "ABIProjection") }
    public static var abiInertProjection: SwiftType { .chain(comModuleName, "ABIInertProjection") }
    public static var boolProjection: SwiftType { .chain(comModuleName, "BoolProjection") }
    public static var wideCharProjection: SwiftType { .chain(comModuleName, "WideCharProjection") }
    public static var guidProjection: SwiftType { .chain(comModuleName, "GUIDProjection") }
    public static var hresultProjection: SwiftType { .chain(comModuleName, "HResultProjection") }

    public static var comExportedInterface: SwiftType { .chain(comModuleName, "COMExportedInterface") }

    public static var comInterop: SwiftType { .chain(comModuleName, "COMInterop") }

    public static func comInterop(of type: SwiftType) -> SwiftType {
        .chain([ .init(comModuleName), .init("COMInterop", genericArgs: [type]) ])
    }
    
    public static var comInteropLazyInitFunc: String { "lazyInit" }

    public static func comArray(of type: SwiftType) -> SwiftType {
        .chain([ .init(comModuleName), .init("COMArray", genericArgs: [type]) ])
    }
}

extension SupportModule {
    public static var winrtModuleName: String { "WindowsRuntime" }

    public static var comIInspectableStruct: SwiftType { .chain(winrtModuleName, "COMIInspectableStruct") }
    public static var eventRegistration: SwiftType { .chain(winrtModuleName, "EventRegistration") }
    public static var eventRegistrationToken: SwiftType { .chain(winrtModuleName, "EventRegistrationToken") }
    public static var hstringProjection: SwiftType { .chain(winrtModuleName, "HStringProjection") }
    public static var iinspectable: SwiftType { .chain(winrtModuleName, "IInspectable") }
    public static var iinspectableProjection: SwiftType { .chain(winrtModuleName, "IInspectableProjection") }

    public static func winRTArrayProjection(of type: SwiftType) -> SwiftType {
        .chain([ .init(winrtModuleName), .init("WinRTArrayProjection", genericArgs: [type]) ])
    }
}

extension SupportModule {
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