import WindowsRuntime_ABI
import COM
import WinSDK
import struct Foundation.UUID

open class WinRTImport<Projection: WinRTProjection & COMProjection>: COMImport<Projection>, IInspectableProtocol {
    private var _inspectableInterop: COMInterop<WindowsRuntime_ABI.SWRT_IInspectable> {
        .init(casting: _interop)
    }

    public func getIids() throws -> [Foundation.UUID] {
        try _inspectableInterop.getIids()
    }

    public func getRuntimeClassName() throws -> String {
        try _inspectableInterop.getRuntimeClassName()
    }

    public func getTrustLevel() throws -> TrustLevel {
        try _inspectableInterop.getTrustLevel()
    }
}