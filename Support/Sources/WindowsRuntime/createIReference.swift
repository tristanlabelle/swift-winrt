import WindowsRuntime_ABI

public func createIReference<BoxableValue: ValueTypeBinding>(_ value: BoxableValue) throws -> WindowsFoundation_IReference<BoxableValue.SwiftValue> {
    try BoxableValue.createIReference(value)
}

public func createIReference<Binding: IReferenceableBinding>(_ value: Binding.SwiftValue, binding: Binding.Type) throws -> WindowsFoundation_IReference<Binding.SwiftValue> {
    try Binding.createIReference(value)
}

public func createIReference(_ value: Bool) throws -> WindowsFoundation_IReference<Bool> { try createIReference(value, binding: BooleanBinding.self) }
public func createIReference(_ value: UInt8) throws -> WindowsFoundation_IReference<UInt8> { try createIReference(value, binding: UInt8Binding.self) }
public func createIReference(_ value: Int16) throws -> WindowsFoundation_IReference<Int16> { try createIReference(value, binding: Int16Binding.self) }
public func createIReference(_ value: UInt16) throws -> WindowsFoundation_IReference<UInt16> { try createIReference(value, binding: UInt16Binding.self) }
public func createIReference(_ value: Int32) throws -> WindowsFoundation_IReference<Int32> { try createIReference(value, binding: Int32Binding.self) }
public func createIReference(_ value: UInt32) throws -> WindowsFoundation_IReference<UInt32> { try createIReference(value, binding: UInt32Binding.self) }
public func createIReference(_ value: Int64) throws -> WindowsFoundation_IReference<Int64> { try createIReference(value, binding: Int64Binding.self) }
public func createIReference(_ value: UInt64) throws -> WindowsFoundation_IReference<UInt64> { try createIReference(value, binding: UInt64Binding.self) }
public func createIReference(_ value: Float) throws -> WindowsFoundation_IReference<Float> { try createIReference(value, binding: SingleBinding.self) }
public func createIReference(_ value: Double) throws -> WindowsFoundation_IReference<Double> { try createIReference(value, binding: DoubleBinding.self) }
public func createIReference(_ value: Char16) throws -> WindowsFoundation_IReference<Char16> { try createIReference(value, binding: Char16Binding.self) }
public func createIReference(_ value: String) throws -> WindowsFoundation_IReference<String> { try createIReference(value, binding: StringBinding.self) }
public func createIReference(_ value: GUID) throws -> WindowsFoundation_IReference<GUID> { try createIReference(value, binding: GuidBinding.self) }

public func createIReferenceArray<BoxableValue: ValueTypeBinding>(_ value: [BoxableValue]) throws -> WindowsFoundation_IReferenceArray<BoxableValue.SwiftValue> {
    try BoxableValue.createIReferenceArray(value)
}

public func createIReferenceArray<Binding: IReferenceableBinding>(_ value: [Binding.SwiftValue], binding: Binding.Type) throws -> WindowsFoundation_IReferenceArray<Binding.SwiftValue> {
    try Binding.createIReferenceArray(value)
}

public func createIReferenceArray(_ value: [Bool]) throws -> WindowsFoundation_IReferenceArray<Bool> { try createIReferenceArray(value, binding: BooleanBinding.self) }
public func createIReferenceArray(_ value: [UInt8]) throws -> WindowsFoundation_IReferenceArray<UInt8> { try createIReferenceArray(value, binding: UInt8Binding.self) }
public func createIReferenceArray(_ value: [Int16]) throws -> WindowsFoundation_IReferenceArray<Int16> { try createIReferenceArray(value, binding: Int16Binding.self) }
public func createIReferenceArray(_ value: [UInt16]) throws -> WindowsFoundation_IReferenceArray<UInt16> { try createIReferenceArray(value, binding: UInt16Binding.self) }
public func createIReferenceArray(_ value: [Int32]) throws -> WindowsFoundation_IReferenceArray<Int32> { try createIReferenceArray(value, binding: Int32Binding.self) }
public func createIReferenceArray(_ value: [UInt32]) throws -> WindowsFoundation_IReferenceArray<UInt32> { try createIReferenceArray(value, binding: UInt32Binding.self) }
public func createIReferenceArray(_ value: [Int64]) throws -> WindowsFoundation_IReferenceArray<Int64> { try createIReferenceArray(value, binding: Int64Binding.self) }
public func createIReferenceArray(_ value: [UInt64]) throws -> WindowsFoundation_IReferenceArray<UInt64> { try createIReferenceArray(value, binding: UInt64Binding.self) }
public func createIReferenceArray(_ value: [Float]) throws -> WindowsFoundation_IReferenceArray<Float> { try createIReferenceArray(value, binding: SingleBinding.self) }
public func createIReferenceArray(_ value: [Double]) throws -> WindowsFoundation_IReferenceArray<Double> { try createIReferenceArray(value, binding: DoubleBinding.self) }
public func createIReferenceArray(_ value: [Char16]) throws -> WindowsFoundation_IReferenceArray<Char16> { try createIReferenceArray(value, binding: Char16Binding.self) }
public func createIReferenceArray(_ value: [String]) throws -> WindowsFoundation_IReferenceArray<String> { try createIReferenceArray(value, binding: StringBinding.self) }
public func createIReferenceArray(_ value: [GUID]) throws -> WindowsFoundation_IReferenceArray<GUID> { try createIReferenceArray(value, binding: GuidBinding.self) }