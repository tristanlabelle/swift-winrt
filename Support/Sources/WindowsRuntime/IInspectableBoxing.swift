import WindowsRuntime_ABI

public enum IInspectableBoxing {
    public static func box(_ value: Bool) throws -> IInspectable { try PrimitiveProjection.Boolean.box(value) }
    public static func box(_ value: UInt8) throws -> IInspectable { try PrimitiveProjection.UInt8.box(value) }
    public static func box(_ value: Int16) throws -> IInspectable { try PrimitiveProjection.Int16.box(value) }
    public static func box(_ value: UInt16) throws -> IInspectable { try PrimitiveProjection.UInt16.box(value) }
    public static func box(_ value: Int32) throws -> IInspectable { try PrimitiveProjection.Int32.box(value) }
    public static func box(_ value: UInt32) throws -> IInspectable { try PrimitiveProjection.UInt32.box(value) }
    public static func box(_ value: Int64) throws -> IInspectable { try PrimitiveProjection.Int64.box(value) }
    public static func box(_ value: UInt64) throws -> IInspectable { try PrimitiveProjection.UInt64.box(value) }
    public static func box(_ value: Float) throws -> IInspectable { try PrimitiveProjection.Single.box(value) }
    public static func box(_ value: Double) throws -> IInspectable { try PrimitiveProjection.Double.box(value) }
    public static func box(_ value: Char16) throws -> IInspectable { try PrimitiveProjection.Char16.box(value) }
    public static func box(_ value: String) throws -> IInspectable { try PrimitiveProjection.String.box(value) }
    public static func box(_ value: GUID) throws -> IInspectable { try PrimitiveProjection.Guid.box(value) }
    public static func box(_ value: WindowsFoundation_DateTime) throws -> IInspectable { try WindowsFoundation_DateTime.box(value) }
    public static func box(_ value: WindowsFoundation_TimeSpan) throws -> IInspectable { try WindowsFoundation_TimeSpan.box(value) }
    public static func box(_ value: WindowsFoundation_Point) throws -> IInspectable { try WindowsFoundation_Point.box(value) }
    public static func box(_ value: WindowsFoundation_Size) throws -> IInspectable { try WindowsFoundation_Size.box(value) }
    public static func box(_ value: WindowsFoundation_Rect) throws -> IInspectable { try WindowsFoundation_Rect.box(value) }

    public static func box<BoxableValue: ValueTypeProjection>(_ value: BoxableValue) throws -> IInspectable {
        try BoxableValue.box(value)
    }

    public static func box<Projection: DelegateProjection>(_ value: Projection.SwiftObject, projection: Projection.Type) throws -> IInspectable {
        try Projection.box(value)
    }

    public static func unboxBoolean(_ inspectable: IInspectable) -> Bool? {
        PrimitiveProjection.Boolean.unbox(inspectable)
    }
    public static func unboxUInt8(_ inspectable: IInspectable) -> UInt8? {
        PrimitiveProjection.UInt8.unbox(inspectable)
    }
    public static func unboxInt16(_ inspectable: IInspectable) -> Int16? {
        PrimitiveProjection.Int16.unbox(inspectable)
    }
    public static func unboxUInt16(_ inspectable: IInspectable) -> UInt16? {
        PrimitiveProjection.UInt16.unbox(inspectable)
    }
    public static func unboxInt32(_ inspectable: IInspectable) -> Int32? {
        PrimitiveProjection.Int32.unbox(inspectable)
    }
    public static func unboxUInt32(_ inspectable: IInspectable) -> UInt32? {
        PrimitiveProjection.UInt32.unbox(inspectable)
    }
    public static func unboxInt64(_ inspectable: IInspectable) -> Int64? {
        PrimitiveProjection.Int64.unbox(inspectable)
    }
    public static func unboxUInt64(_ inspectable: IInspectable) -> UInt64? {
        PrimitiveProjection.UInt64.unbox(inspectable)
    }
    public static func unboxSingle(_ inspectable: IInspectable) -> Float? {
        PrimitiveProjection.Single.unbox(inspectable)
    }
    public static func unboxDouble(_ inspectable: IInspectable) -> Double? {
        PrimitiveProjection.Double.unbox(inspectable)
    }
    public static func unboxChar16(_ inspectable: IInspectable) -> Char16? {
        PrimitiveProjection.Char16.unbox(inspectable)
    }
    public static func unboxString(_ inspectable: IInspectable) -> String? {
        PrimitiveProjection.String.unbox(inspectable)
    }
    public static func unboxGuid(_ inspectable: IInspectable) -> GUID? {
        PrimitiveProjection.Guid.unbox(inspectable)
    }
    public static func unbox<Projection: ValueTypeProjection>(_ inspectable: IInspectable, projection: Projection.Type) -> Projection.SwiftValue? {
        Projection.unbox(inspectable)
    }
    public static func unbox<Projection: DelegateProjection>(_ inspectable: IInspectable, projection: Projection.Type) -> Projection.SwiftObject? {
        Projection.unbox(inspectable).flatMap { $0! } // If we unboxed, the inner optional is non-nil
    }
}
