import WindowsRuntime_ABI

internal class ReferenceBox<BoxableProjection: WinRTBoxableProjection>
        : WinRTExport<WindowsFoundation_IReferenceProjection<BoxableProjection>>,
        WindowsFoundation_IReferenceProtocol {
    public typealias T = BoxableProjection.SwiftValue

    public override class var _runtimeClassName: String { "Windows.Foundation.IReference`1<\(BoxableProjection.typeName)>" }

    private let value: BoxableProjection.SwiftValue

    init(_ value: BoxableProjection.SwiftValue) {
        self.value = value
        super.init()
    }

    // IPropertyValue members
    public func _type() throws -> WindowsFoundation_PropertyType { .otherType }
    public func _isNumericScalar() throws -> Bool { false }

    public func _value() throws -> T { value }
    public func _getABIValue(_ pointer: UnsafeMutableRawPointer) throws {
        pointer.bindMemory(to: BoxableProjection.ABIValue.self, capacity: 1).pointee = try BoxableProjection.toABI(value)
    }
}
