import COM
import WindowsRuntime

internal final class SwiftObject: WinRTPrimaryExport<IInspectable2Binding>, IInspectable2Protocol, IUnknown2Protocol {
    override class var implements: [COMImplements] { [
        .init(IInspectable2Binding.self),
        .init(IUnknown2Binding.self)
    ] }
}