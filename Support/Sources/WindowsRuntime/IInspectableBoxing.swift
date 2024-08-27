import WindowsRuntime_ABI

public enum IInspectableBoxing {
    public static func box<BoxableValue: ValueTypeProjection>(_ value: BoxableValue) throws -> IInspectable {
        try BoxableValue.box(value)
    }

    public static func box<Projection: BoxableProjection>(_ value: Projection.SwiftValue, projection: Projection.Type) throws -> IInspectable {
        try Projection.box(value)
    }

    public static func box<BoxableValue: ValueTypeProjection>(_ value: [BoxableValue]) throws -> IInspectable {
        try BoxableValue.boxArray(value)
    }

    public static func box<Projection: BoxableProjection>(_ value: [Projection.SwiftValue], projection: Projection.Type) throws -> IInspectable {
        try Projection.boxArray(value)
    }

    public static func box(_ value: Bool) throws -> IInspectable { try box(value, projection: PrimitiveProjection.Boolean.self) }
    public static func box(_ value: UInt8) throws -> IInspectable { try box(value, projection: PrimitiveProjection.UInt8.self) }
    public static func box(_ value: Int16) throws -> IInspectable { try box(value, projection: PrimitiveProjection.Int16.self) }
    public static func box(_ value: UInt16) throws -> IInspectable { try box(value, projection: PrimitiveProjection.UInt16.self) }
    public static func box(_ value: Int32) throws -> IInspectable { try box(value, projection: PrimitiveProjection.Int32.self) }
    public static func box(_ value: UInt32) throws -> IInspectable { try box(value, projection: PrimitiveProjection.UInt32.self) }
    public static func box(_ value: Int64) throws -> IInspectable { try box(value, projection: PrimitiveProjection.Int64.self) }
    public static func box(_ value: UInt64) throws -> IInspectable { try box(value, projection: PrimitiveProjection.UInt64.self) }
    public static func box(_ value: Float) throws -> IInspectable { try box(value, projection: PrimitiveProjection.Single.self) }
    public static func box(_ value: Double) throws -> IInspectable { try box(value, projection: PrimitiveProjection.Double.self) }
    public static func box(_ value: Char16) throws -> IInspectable { try box(value, projection: PrimitiveProjection.Char16.self) }
    public static func box(_ value: String) throws -> IInspectable { try box(value, projection: PrimitiveProjection.String.self) }
    public static func box(_ value: GUID) throws -> IInspectable { try box(value, projection: PrimitiveProjection.Guid.self) }

    public static func box(_ value: [Bool]) throws -> IInspectable { try box(value, projection: PrimitiveProjection.Boolean.self) }
    public static func box(_ value: [UInt8]) throws -> IInspectable { try box(value, projection: PrimitiveProjection.UInt8.self) }
    public static func box(_ value: [Int16]) throws -> IInspectable { try box(value, projection: PrimitiveProjection.Int16.self) }
    public static func box(_ value: [UInt16]) throws -> IInspectable { try box(value, projection: PrimitiveProjection.UInt16.self) }
    public static func box(_ value: [Int32]) throws -> IInspectable { try box(value, projection: PrimitiveProjection.Int32.self) }
    public static func box(_ value: [UInt32]) throws -> IInspectable { try box(value, projection: PrimitiveProjection.UInt32.self) }
    public static func box(_ value: [Int64]) throws -> IInspectable { try box(value, projection: PrimitiveProjection.Int64.self) }
    public static func box(_ value: [UInt64]) throws -> IInspectable { try box(value, projection: PrimitiveProjection.UInt64.self) }
    public static func box(_ value: [Float]) throws -> IInspectable { try box(value, projection: PrimitiveProjection.Single.self) }
    public static func box(_ value: [Double]) throws -> IInspectable { try box(value, projection: PrimitiveProjection.Double.self) }
    public static func box(_ value: [Char16]) throws -> IInspectable { try box(value, projection: PrimitiveProjection.Char16.self) }
    public static func box(_ value: [String]) throws -> IInspectable { try box(value, projection: PrimitiveProjection.String.self) }
    public static func box(_ value: [GUID]) throws -> IInspectable { try box(value, projection: PrimitiveProjection.Guid.self) }

    public static func unbox<Projection: BoxableProjection>(_ inspectable: IInspectable, projection: Projection.Type) throws -> Projection.SwiftValue {
        try Projection.unbox(inspectable)
    }

    public static func unboxArray<Projection: BoxableProjection>(_ inspectable: IInspectable, projection: Projection.Type) throws -> [Projection.SwiftValue] {
        try Projection.unboxArray(inspectable)
    }

    public static func unboxBoolean(_ inspectable: IInspectable) throws -> Bool? { try unbox(inspectable, projection: PrimitiveProjection.Boolean.self) }
    public static func unboxUInt8(_ inspectable: IInspectable) throws -> UInt8? { try unbox(inspectable, projection: PrimitiveProjection.UInt8.self) }
    public static func unboxInt16(_ inspectable: IInspectable) throws -> Int16? { try unbox(inspectable, projection: PrimitiveProjection.Int16.self) }
    public static func unboxUInt16(_ inspectable: IInspectable) throws -> UInt16? { try unbox(inspectable, projection: PrimitiveProjection.UInt16.self) }
    public static func unboxInt32(_ inspectable: IInspectable) throws -> Int32? { try unbox(inspectable, projection: PrimitiveProjection.Int32.self) }
    public static func unboxUInt32(_ inspectable: IInspectable) throws -> UInt32? { try unbox(inspectable, projection: PrimitiveProjection.UInt32.self) }
    public static func unboxInt64(_ inspectable: IInspectable) throws -> Int64? { try unbox(inspectable, projection: PrimitiveProjection.Int64.self) }
    public static func unboxUInt64(_ inspectable: IInspectable) throws -> UInt64? { try unbox(inspectable, projection: PrimitiveProjection.UInt64.self) }
    public static func unboxSingle(_ inspectable: IInspectable) throws -> Float? { try unbox(inspectable, projection: PrimitiveProjection.Single.self) }
    public static func unboxDouble(_ inspectable: IInspectable) throws -> Double? { try unbox(inspectable, projection: PrimitiveProjection.Double.self) }
    public static func unboxChar16(_ inspectable: IInspectable) throws -> Char16? { try unbox(inspectable, projection: PrimitiveProjection.Char16.self) }
    public static func unboxString(_ inspectable: IInspectable) throws -> String? { try unbox(inspectable, projection: PrimitiveProjection.String.self) }
    public static func unboxGuid(_ inspectable: IInspectable) throws -> GUID? { try unbox(inspectable, projection: PrimitiveProjection.Guid.self) }

    public static func unboxBooleanArray(_ inspectable: IInspectable) throws -> [Bool] { try unboxArray(inspectable, projection: PrimitiveProjection.Boolean.self) }
    public static func unboxUInt8Array(_ inspectable: IInspectable) throws -> [UInt8] { try unboxArray(inspectable, projection: PrimitiveProjection.UInt8.self) }
    public static func unboxInt16Array(_ inspectable: IInspectable) throws -> [Int16] { try unboxArray(inspectable, projection: PrimitiveProjection.Int16.self) }
    public static func unboxUInt16Array(_ inspectable: IInspectable) throws -> [UInt16] { try unboxArray(inspectable, projection: PrimitiveProjection.UInt16.self) }
    public static func unboxInt32Array(_ inspectable: IInspectable) throws -> [Int32] { try unboxArray(inspectable, projection: PrimitiveProjection.Int32.self) }
    public static func unboxUInt32Array(_ inspectable: IInspectable) throws -> [UInt32] { try unboxArray(inspectable, projection: PrimitiveProjection.UInt32.self) }
    public static func unboxInt64Array(_ inspectable: IInspectable) throws -> [Int64] { try unboxArray(inspectable, projection: PrimitiveProjection.Int64.self) }
    public static func unboxUInt64Array(_ inspectable: IInspectable) throws -> [UInt64] { try unboxArray(inspectable, projection: PrimitiveProjection.UInt64.self) }
    public static func unboxSingleArray(_ inspectable: IInspectable) throws -> [Float] { try unboxArray(inspectable, projection: PrimitiveProjection.Single.self) }
    public static func unboxDoubleArray(_ inspectable: IInspectable) throws -> [Double] { try unboxArray(inspectable, projection: PrimitiveProjection.Double.self) }
    public static func unboxChar16Array(_ inspectable: IInspectable) throws -> [Char16] { try unboxArray(inspectable, projection: PrimitiveProjection.Char16.self) }
    public static func unboxStringArray(_ inspectable: IInspectable) throws -> [String] { try unboxArray(inspectable, projection: PrimitiveProjection.String.self) }
    public static func unboxGuidArray(_ inspectable: IInspectable) throws -> [GUID] { try unboxArray(inspectable, projection: PrimitiveProjection.Guid.self) }
}
