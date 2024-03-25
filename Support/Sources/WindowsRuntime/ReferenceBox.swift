import WindowsRuntime_ABI

internal class ReferenceBox<BoxableProjection: WinRTBoxableProjection>
        : WinRTExport<WindowsFoundation_IReferenceProjection<BoxableProjection>>,
        WindowsFoundation_IReferenceProtocol {
    public typealias T = BoxableProjection.SwiftValue

    private let value: BoxableProjection.SwiftValue

    init(_ value: BoxableProjection.SwiftValue) {
        self.value = value
        super.init()
    }

    public func _value() throws -> T { value }
}
