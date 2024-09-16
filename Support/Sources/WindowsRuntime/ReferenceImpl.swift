import WindowsRuntime_ABI

/// Implements IReference<T> for any boxable T not provided by the UWP PropertyValue class (value types and delegates).
internal class ReferenceImpl<TBinding: IReferenceableBinding>
        : WinRTPrimaryExport<WindowsFoundation_IReferenceBinding<TBinding>>,
        WindowsFoundation_IReferenceProtocol {
    public typealias T = TBinding.SwiftValue

    public override class var _runtimeClassName: String { "Windows.Foundation.IReference`1<\(TBinding.typeName)>" }

    private let value: TBinding.SwiftValue

    init(_ value: TBinding.SwiftValue) {
        self.value = value
        super.init()
    }

    // IPropertyValue members
    public func _type() throws -> WindowsFoundation_PropertyType { .otherType }
    public func _isNumericScalar() throws -> Bool { false }

    public func _value() throws -> T { value }
    public func _getABIValue(_ pointer: UnsafeMutableRawPointer) throws {
        pointer.bindMemory(to: TBinding.ABIValue.self, capacity: 1).pointee = try TBinding.toABI(value)
    }
}
