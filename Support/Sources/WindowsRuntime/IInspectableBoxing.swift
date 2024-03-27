import WindowsRuntime_ABI
import struct Foundation.UUID

public enum IInspectableBoxing {
    public static func box(_ value: Bool) throws -> IInspectable { try WinRTPrimitiveProjection.Boolean.box(value) }
    public static func box(_ value: UInt8) throws -> IInspectable { try WinRTPrimitiveProjection.UInt8.box(value) }
    public static func box(_ value: Int16) throws -> IInspectable { try WinRTPrimitiveProjection.Int16.box(value) }
    public static func box(_ value: UInt16) throws -> IInspectable { try WinRTPrimitiveProjection.UInt16.box(value) }
    public static func box(_ value: Int32) throws -> IInspectable { try WinRTPrimitiveProjection.Int32.box(value) }
    public static func box(_ value: UInt32) throws -> IInspectable { try WinRTPrimitiveProjection.UInt32.box(value) }
    public static func box(_ value: Int64) throws -> IInspectable { try WinRTPrimitiveProjection.Int64.box(value) }
    public static func box(_ value: UInt64) throws -> IInspectable { try WinRTPrimitiveProjection.UInt64.box(value) }
    public static func box(_ value: Float) throws -> IInspectable { try WinRTPrimitiveProjection.Single.box(value) }
    public static func box(_ value: Double) throws -> IInspectable { try WinRTPrimitiveProjection.Double.box(value) }
    public static func box(_ value: Char16) throws -> IInspectable { try WinRTPrimitiveProjection.Char16.box(value) }
    public static func box(_ value: String) throws -> IInspectable { try WinRTPrimitiveProjection.String.box(value) }
    public static func box(_ value: UUID) throws -> IInspectable { try WinRTPrimitiveProjection.Guid.box(value) }
    public static func box<BoxableValue: WinRTBoxableProjection>(_ value: BoxableValue) throws -> IInspectable
            where BoxableValue.SwiftValue == BoxableValue {
        try BoxableValue.box(value)
    }

    public static func unboxBoolean(_ inspectable: IInspectable) -> Bool? {
        WinRTPrimitiveProjection.Boolean.unbox(inspectable)
    }
    public static func unboxUInt8(_ inspectable: IInspectable) -> UInt8? {
        WinRTPrimitiveProjection.UInt8.unbox(inspectable)
    }
    public static func unboxInt16(_ inspectable: IInspectable) -> Int16? {
        WinRTPrimitiveProjection.Int16.unbox(inspectable)
    }
    public static func unboxUInt16(_ inspectable: IInspectable) -> UInt16? {
        WinRTPrimitiveProjection.UInt16.unbox(inspectable)
    }
    public static func unboxInt32(_ inspectable: IInspectable) -> Int32? {
        WinRTPrimitiveProjection.Int32.unbox(inspectable)
    }
    public static func unboxUInt32(_ inspectable: IInspectable) -> UInt32? {
        WinRTPrimitiveProjection.UInt32.unbox(inspectable)
    }
    public static func unboxInt64(_ inspectable: IInspectable) -> Int64? {
        WinRTPrimitiveProjection.Int64.unbox(inspectable)
    }
    public static func unboxUInt64(_ inspectable: IInspectable) -> UInt64? {
        WinRTPrimitiveProjection.UInt64.unbox(inspectable)
    }
    public static func unboxSingle(_ inspectable: IInspectable) -> Float? {
        WinRTPrimitiveProjection.Single.unbox(inspectable)
    }
    public static func unboxDouble(_ inspectable: IInspectable) -> Double? {
        WinRTPrimitiveProjection.Double.unbox(inspectable)
    }
    public static func unboxChar16(_ inspectable: IInspectable) -> Char16? {
        WinRTPrimitiveProjection.Char16.unbox(inspectable)
    }
    public static func unboxString(_ inspectable: IInspectable) -> String? {
        WinRTPrimitiveProjection.String.unbox(inspectable)
    }
    public static func unboxGuid(_ inspectable: IInspectable) -> UUID? {
        WinRTPrimitiveProjection.Guid.unbox(inspectable)
    }
    public static func unbox<Projection: WinRTBoxableProjection>(_ inspectable: IInspectable, projection: Projection.Type) -> Projection.SwiftValue? {
        Projection.unbox(inspectable)
    }
}
