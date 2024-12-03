import WindowsRuntime_ABI

/// Implements IReference<T> for any boxable T not provided by the UWP PropertyValue class (value types and delegates).
internal class ReferenceImpl<TBinding: IReferenceableBinding>
        : WinRTExport<WindowsFoundation_IReferenceBinding<TBinding>>,
        WindowsFoundation_IReferenceProtocol {
    public typealias T = TBinding.SwiftValue

    public override class var _runtimeClassName: String { "Windows.Foundation.IReference`1<\(TBinding.typeName)>" }

    private let _value: TBinding.SwiftValue

    init(_ value: TBinding.SwiftValue) {
        self._value = value
        super.init()
    }

    // IPropertyValue members
    public var type: WindowsFoundation_PropertyType { get throws { .otherType } }
    public var isNumericScalar: Bool { get throws { false } }
    public var value: T { get throws { _value } }

    public func _getABIValue(_ pointer: UnsafeMutableRawPointer) throws {
        pointer.bindMemory(to: TBinding.ABIValue.self, capacity: 1).pointee = try TBinding.toABI(_value)
    }
}
