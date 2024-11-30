import COM
import WindowsRuntime

internal final class SwiftObject: WinRTPrimaryExport<IWinRTTestBinding>, IWinRTTestProtocol, ICOMTestProtocol {
    override class var implements: [COMImplements] { [
        .init(IWinRTTestBinding.self),
        .init(ICOMTestBinding.self)
    ] }

    private(set) var comTestCallCount: Int = 0
    private(set) var winRTTestCallCount: Int = 0

    func comTest() throws { comTestCallCount += 1 }
    func winRTTest() throws { winRTTestCallCount += 1 }
}