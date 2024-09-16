import WindowsRuntime_ABI
import COM
import WinSDK

open class WinRTImport<Binding: WinRTBinding & COMBinding>: COMImport<Binding>, IInspectableProtocol {
    private var _inspectableInterop: COMInterop<WindowsRuntime_ABI.SWRT_IInspectable> {
        .init(casting: _interop)
    }

    public func getIids() throws -> [COMInterfaceID] {
        try _inspectableInterop.getIids()
    }

    public func getRuntimeClassName() throws -> String {
        try _inspectableInterop.getRuntimeClassName()
    }

    public func getTrustLevel() throws -> TrustLevel {
        try _inspectableInterop.getTrustLevel()
    }
}