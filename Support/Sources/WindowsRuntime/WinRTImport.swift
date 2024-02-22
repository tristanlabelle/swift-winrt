import CWinRTCore
import COM
import WinSDK
import struct Foundation.UUID

open class WinRTImport<Projection: WinRTProjection>: COMImport<Projection>, IInspectableProtocol {
    private var _inspectableInterop: COMInterop<CWinRTCore.SWRT_IInspectable> {
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