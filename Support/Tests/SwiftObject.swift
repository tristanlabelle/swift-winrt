import COM
import WindowsRuntime

internal final class SwiftObject: WinRTExport<IInspectable2Projection>, IInspectable2Protocol, IUnknown2Protocol {
    override class var implements: [COMImplements] { [
        .init(IInspectable2Projection.self),
        .init(IUnknown2Projection.self)
    ] }
}