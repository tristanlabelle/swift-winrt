import WindowsRuntime_ABI

/// Implements IReferenceArray<T> for any boxable T not provided by the UWP PropertyValue class (value types and delegates).
internal class ReferenceArrayImpl<TBinding: IReferenceableBinding>
        : WinRTPrimaryExport<WindowsFoundation_IReferenceArrayBinding<TBinding>>,
        WindowsFoundation_IReferenceArrayProtocol {
    public typealias T = TBinding.SwiftValue

    public override class var _runtimeClassName: String { "Windows.Foundation.IReferenceArray`1<\(TBinding.typeName)>" }

    private let _value: [TBinding.SwiftValue]

    init(_ value: [TBinding.SwiftValue]) {
        self._value = value
        super.init()
    }

    // IPropertyValue members
    public var type: WindowsFoundation_PropertyType { get throws { .otherTypeArray } }
    public var isNumericScalar: Bool { get throws { false } }

    public var value: [T] { get throws { _value } }

    public func _getABIValue(_ length: inout UInt32, _ pointer: inout UnsafeMutableRawPointer?) throws {
        let abiValue = try ArrayBinding<TBinding>.toABI(self._value)
        length = abiValue.count
        pointer = abiValue.pointer.map { UnsafeMutableRawPointer($0) }
    }
}
