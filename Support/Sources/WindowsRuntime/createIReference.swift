import WindowsRuntime_ABI

public func createIReference<BoxableValue: ValueTypeProjection>(_ value: BoxableValue) throws -> WindowsFoundation_IReference<BoxableValue.SwiftValue> {
    try BoxableValue.createIReference(value)
}

public func createIReference<Projection: IReferenceableProjection>(_ value: Projection.SwiftValue, projection: Projection.Type) throws -> WindowsFoundation_IReference<Projection.SwiftValue> {
    try Projection.createIReference(value)
}

public func createIReference(_ value: Bool) throws -> WindowsFoundation_IReference<Bool> { try createIReference(value, projection: BooleanProjection.self) }
public func createIReference(_ value: UInt8) throws -> WindowsFoundation_IReference<UInt8> { try createIReference(value, projection: UInt8Projection.self) }
public func createIReference(_ value: Int16) throws -> WindowsFoundation_IReference<Int16> { try createIReference(value, projection: Int16Projection.self) }
public func createIReference(_ value: UInt16) throws -> WindowsFoundation_IReference<UInt16> { try createIReference(value, projection: UInt16Projection.self) }
public func createIReference(_ value: Int32) throws -> WindowsFoundation_IReference<Int32> { try createIReference(value, projection: Int32Projection.self) }
public func createIReference(_ value: UInt32) throws -> WindowsFoundation_IReference<UInt32> { try createIReference(value, projection: UInt32Projection.self) }
public func createIReference(_ value: Int64) throws -> WindowsFoundation_IReference<Int64> { try createIReference(value, projection: Int64Projection.self) }
public func createIReference(_ value: UInt64) throws -> WindowsFoundation_IReference<UInt64> { try createIReference(value, projection: UInt64Projection.self) }
public func createIReference(_ value: Float) throws -> WindowsFoundation_IReference<Float> { try createIReference(value, projection: SingleProjection.self) }
public func createIReference(_ value: Double) throws -> WindowsFoundation_IReference<Double> { try createIReference(value, projection: DoubleProjection.self) }
public func createIReference(_ value: Char16) throws -> WindowsFoundation_IReference<Char16> { try createIReference(value, projection: Char16Projection.self) }
public func createIReference(_ value: String) throws -> WindowsFoundation_IReference<String> { try createIReference(value, projection: StringProjection.self) }
public func createIReference(_ value: GUID) throws -> WindowsFoundation_IReference<GUID> { try createIReference(value, projection: GuidProjection.self) }

public func createIReferenceArray<BoxableValue: ValueTypeProjection>(_ value: [BoxableValue]) throws -> WindowsFoundation_IReferenceArray<BoxableValue.SwiftValue> {
    try BoxableValue.createIReferenceArray(value)
}

public func createIReferenceArray<Projection: IReferenceableProjection>(_ value: [Projection.SwiftValue], projection: Projection.Type) throws -> WindowsFoundation_IReferenceArray<Projection.SwiftValue> {
    try Projection.createIReferenceArray(value)
}

public func createIReferenceArray(_ value: [Bool]) throws -> WindowsFoundation_IReferenceArray<Bool> { try createIReferenceArray(value, projection: BooleanProjection.self) }
public func createIReferenceArray(_ value: [UInt8]) throws -> WindowsFoundation_IReferenceArray<UInt8> { try createIReferenceArray(value, projection: UInt8Projection.self) }
public func createIReferenceArray(_ value: [Int16]) throws -> WindowsFoundation_IReferenceArray<Int16> { try createIReferenceArray(value, projection: Int16Projection.self) }
public func createIReferenceArray(_ value: [UInt16]) throws -> WindowsFoundation_IReferenceArray<UInt16> { try createIReferenceArray(value, projection: UInt16Projection.self) }
public func createIReferenceArray(_ value: [Int32]) throws -> WindowsFoundation_IReferenceArray<Int32> { try createIReferenceArray(value, projection: Int32Projection.self) }
public func createIReferenceArray(_ value: [UInt32]) throws -> WindowsFoundation_IReferenceArray<UInt32> { try createIReferenceArray(value, projection: UInt32Projection.self) }
public func createIReferenceArray(_ value: [Int64]) throws -> WindowsFoundation_IReferenceArray<Int64> { try createIReferenceArray(value, projection: Int64Projection.self) }
public func createIReferenceArray(_ value: [UInt64]) throws -> WindowsFoundation_IReferenceArray<UInt64> { try createIReferenceArray(value, projection: UInt64Projection.self) }
public func createIReferenceArray(_ value: [Float]) throws -> WindowsFoundation_IReferenceArray<Float> { try createIReferenceArray(value, projection: SingleProjection.self) }
public func createIReferenceArray(_ value: [Double]) throws -> WindowsFoundation_IReferenceArray<Double> { try createIReferenceArray(value, projection: DoubleProjection.self) }
public func createIReferenceArray(_ value: [Char16]) throws -> WindowsFoundation_IReferenceArray<Char16> { try createIReferenceArray(value, projection: Char16Projection.self) }
public func createIReferenceArray(_ value: [String]) throws -> WindowsFoundation_IReferenceArray<String> { try createIReferenceArray(value, projection: StringProjection.self) }
public func createIReferenceArray(_ value: [GUID]) throws -> WindowsFoundation_IReferenceArray<GUID> { try createIReferenceArray(value, projection: GuidProjection.self) }