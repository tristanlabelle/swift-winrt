import CWinRTCore
import COM
import WinSDK
import struct Foundation.UUID

open class WinRTImport<Projection: WinRTProjection>: COMImport<Projection>, IInspectableProtocol {
    private var _inspectable: UnsafeMutablePointer<CWinRTCore.SWRT_IInspectable> {
        comPointer.withMemoryRebound(to: CWinRTCore.SWRT_IInspectable.self, capacity: 1) { $0 }
    }

    public func getIids() throws -> [Foundation.UUID] {
        try COMInterop(_inspectable).getIids()
    }

    public func getRuntimeClassName() throws -> String {
        try COMInterop(_inspectable).getRuntimeClassName()
    }

    public func getTrustLevel() throws -> TrustLevel {
        try COMInterop(_inspectable).getTrustLevel()
    }
}