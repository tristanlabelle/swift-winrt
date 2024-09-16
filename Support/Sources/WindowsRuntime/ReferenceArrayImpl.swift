import WindowsRuntime_ABI

/// Implements IReferenceArray<T> for any boxable T not provided by the UWP PropertyValue class (value types and delegates).
internal class ReferenceArrayImpl<TBinding: IReferenceableBinding>
        : WinRTPrimaryExport<WindowsFoundation_IReferenceArrayBinding<TBinding>>,
        WindowsFoundation_IReferenceArrayProtocol {
    public typealias T = TBinding.SwiftValue

    public override class var _runtimeClassName: String { "Windows.Foundation.IReferenceArray`1<\(TBinding.typeName)>" }

    private let value: [TBinding.SwiftValue]

    init(_ value: [TBinding.SwiftValue]) {
        self.value = value
        super.init()
    }

    // IPropertyValue members
    public func _type() throws -> WindowsFoundation_PropertyType { .otherTypeArray }
    public func _isNumericScalar() throws -> Bool { false }

    public func _value() throws -> [T] { value }
    public func _getABIValue(_ length: inout UInt32, _ pointer: inout UnsafeMutableRawPointer?) throws {
        let abiValue = try ArrayBinding<TBinding>.toABI(self.value)
        length = abiValue.count
        pointer = abiValue.pointer.map { UnsafeMutableRawPointer($0) }
    }
}
