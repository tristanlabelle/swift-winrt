import COM
import WindowsRuntime

internal final class SwiftObject: WinRTExportBase<IInspectable2Projection>, IInspectable2Protocol, IUnknown2Protocol {
    override class var queriableInterfaces: [COMExportInterface] { [
        .init(IInspectable2Projection.self),
        .init(IUnknown2Projection.self)
    ] }
}