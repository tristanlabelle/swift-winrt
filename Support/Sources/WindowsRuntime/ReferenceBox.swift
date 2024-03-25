internal class ReferenceBox<BoxableProjection: WinRTBoxableProjection>: WinRTExport<IInspectableProjection> {
    private let value: BoxableProjection.SwiftValue

    init(_ value: BoxableProjection.SwiftValue) {
        self.value = value
        super.init()
    }
}