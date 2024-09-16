/// Specifies property value types.
public struct WindowsFoundation_PropertyType: RawRepresentable, Hashable, Codable, Sendable {
    public var rawValue: Swift.Int32

    public init(rawValue: Swift.Int32 = 0) {
        self.rawValue = rawValue
    }

    /// No type is specified.
    public static let empty = Self()

    /// A byte.
    public static let uint8 = Self(rawValue: 1)

    /// A signed 16-bit (2-byte) integer.
    public static let int16 = Self(rawValue: 2)

    /// An unsigned 16-bit (2-byte) integer.
    public static let uint16 = Self(rawValue: 3)

    /// A signed 32-bit (4-byte) integer.
    public static let int32 = Self(rawValue: 4)

    /// An unsigned 32-bit (4-byte) integer.
    public static let uint32 = Self(rawValue: 5)

    /// A signed 64-bit (8-byte) integer.
    public static let int64 = Self(rawValue: 6)

    /// An unsigned 64-bit (8-byte) integer.
    public static let uint64 = Self(rawValue: 7)

    /// A signed 32-bit (4-byte) floating-point number.
    public static let single = Self(rawValue: 8)

    /// A signed 64-bit (8-byte) floating-point number.
    public static let double = Self(rawValue: 9)

    /// An unsigned 16-bit (2-byte) code point.
    public static let char16 = Self(rawValue: 10)

    /// A value that can be only true or false.
    public static let boolean = Self(rawValue: 11)

    /// A Windows Runtime  HSTRING.
    public static let string = Self(rawValue: 12)

    /// An object implementing the IInspectable interface.
    public static let inspectable = Self(rawValue: 13)

    /// An instant in time, typically expressed as a date and time of day.
    public static let dateTime = Self(rawValue: 14)

    /// A time interval.
    public static let timeSpan = Self(rawValue: 15)

    /// A globally unique identifier.
    public static let guid = Self(rawValue: 16)

    /// An ordered pair of floating-point x- and y-coordinates that defines a point in a two-dimensional plane.
    public static let point = Self(rawValue: 17)

    /// An ordered pair of float-point numbers that specify a height and width.
    public static let size = Self(rawValue: 18)

    /// A set of four floating-point numbers that represent the location and size of a rectangle.
    public static let rect = Self(rawValue: 19)

    /// A type not specified in this enumeration.
    public static let otherType = Self(rawValue: 20)

    /// An array of Byte values.
    public static let uint8Array = Self(rawValue: 1025)

    /// An array of Int16 values.
    public static let int16Array = Self(rawValue: 1026)

    /// An array of UInt16 values.
    public static let uint16Array = Self(rawValue: 1027)

    /// An array of Int32 values.
    public static let int32Array = Self(rawValue: 1028)

    /// An array of UInt32 values.
    public static let uint32Array = Self(rawValue: 1029)

    /// An array of Int64 values.
    public static let int64Array = Self(rawValue: 1030)

    /// An array of UInt64 values.
    public static let uint64Array = Self(rawValue: 1031)

    /// An array of Single values.
    public static let singleArray = Self(rawValue: 1032)

    /// An array of Double values.
    public static let doubleArray = Self(rawValue: 1033)

    /// An array of Char values.
    public static let char16Array = Self(rawValue: 1034)

    /// An array of Boolean values.
    public static let booleanArray = Self(rawValue: 1035)

    /// An array of String values.
    public static let stringArray = Self(rawValue: 1036)

    /// An array of **Inspectable** values.
    public static let inspectableArray = Self(rawValue: 1037)

    /// An array of DateTime values.
    public static let dateTimeArray = Self(rawValue: 1038)

    /// An array of TimeSpan values.
    public static let timeSpanArray = Self(rawValue: 1039)

    /// An array of Guid values.
    public static let guidArray = Self(rawValue: 1040)

    /// An array of Point structures.
    public static let pointArray = Self(rawValue: 1041)

    /// An array of Size structures.
    public static let sizeArray = Self(rawValue: 1042)

    /// An array of Rect structures.
    public static let rectArray = Self(rawValue: 1043)

    /// An array of an unspecified type.
    public static let otherTypeArray = Self(rawValue: 1044)
}

extension WindowsFoundation_PropertyType: WindowsRuntime.OpenEnumBinding {
    public static let typeName = "Windows.Foundation.PropertyType"

    public static var ireferenceID: COM.COMInterfaceID {
        COMInterfaceID(0xECEBDE54, 0xFAC0, 0x5AEB, 0x9BA9, 0x9E1FE17E31D5)
    }

    public static var ireferenceArrayID: COM.COMInterfaceID {
        COMInterfaceID(0x98EC8AA6, 0x118D, 0x5FC5, 0xB263, 0x3AABFBEE504D)
    }
}