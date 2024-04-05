import WindowsRuntime_ABI

internal class ReferenceBox<TProjection: BoxableProjection>
        : WinRTExport<WindowsFoundation_IReferenceProjection<TProjection>>,
        WindowsFoundation_IReferenceProtocol {
    public typealias T = TProjection.SwiftValue

    public override class var _runtimeClassName: String { "Windows.Foundation.IReference`1<\(TProjection.typeName)>" }

    private let value: TProjection.SwiftValue

    init(_ value: TProjection.SwiftValue) {
        self.value = value
        super.init()
    }

    // IPropertyValue members
    public func _type() throws -> WindowsFoundation_PropertyType { .otherType }
    public func _isNumericScalar() throws -> Bool { false }

    public func _value() throws -> T { value }
    public func _getABIValue(_ pointer: UnsafeMutableRawPointer) throws {
        pointer.bindMemory(to: TProjection.ABIValue.self, capacity: 1).pointee = try TProjection.toABI(value)
    }
}
