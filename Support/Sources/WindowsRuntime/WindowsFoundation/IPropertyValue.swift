import struct Foundation.UUID

public typealias WindowsFoundation_IPropertyValue = any WindowsFoundation_IPropertyValueProtocol
public protocol WindowsFoundation_IPropertyValueProtocol: IInspectableProtocol {
    // var type: SWRT_WindowsFoundation_PropertyType { get }
    // var isNumericScalar: Bool { get }
    func getUInt8() throws -> UInt8
    func getInt16() throws -> Int16
    func getUInt16() throws -> UInt16
    func getInt32() throws -> Int32
    func getUInt32() throws -> UInt32
    func getInt64() throws -> Int64
    func getUInt64() throws -> UInt64
    func getSingle() throws -> Float
    func getDouble() throws -> Double
    func getChar16() throws -> Char16
    func getBoolean() throws -> Bool
    func getString() throws -> String
    func getGuid() throws -> UUID
    // func getDateTime() throws -> WindowsFoundation_DateTime
    // func getTimeSpan() throws -> WindowsFoundation_TimeSpan
    // func getPoint() throws -> WindowsFoundation_Point
    // func getSize() throws -> WindowsFoundation_Size
    // func getRect() throws -> WindowsFoundation_Rect
    func getUInt8Array() throws -> [UInt8]
    func getInt16Array() throws -> [Int16]
    func getUInt16Array() throws -> [UInt16]
    func getInt32Array() throws -> [Int32]
    func getUInt32Array() throws -> [UInt32]
    func getInt64Array() throws -> [Int64]
    func getUInt64Array() throws -> [UInt64]
    func getSingleArray() throws -> [Float]
    func getDoubleArray() throws -> [Double]
    func getChar16Array() throws -> [Char16]
    func getBooleanArray() throws -> [Bool]
    func getStringArray() throws -> [String]
    func getInspectableArray() throws -> [IInspectable]
    func getGuidArray() throws -> [UUID]
    // func getDateTimeArray() throws -> [WindowsFoundation_DateTime]
    // func getTimeSpanArray() throws -> [WindowsFoundation_TimeSpan]
    // func getPointArray() throws -> [WindowsFoundation_Point]
    // func getSizeArray() throws -> [WindowsFoundation_Size]
    // func getRectArray() throws -> [WindowsFoundation_Rect]
}

extension WindowsFoundation_IPropertyValueProtocol {
    public func getUInt8() throws -> UInt8 { throw HResult.Error.notImpl }
    public func getInt16() throws -> Int16 { throw HResult.Error.notImpl }
    public func getUInt16() throws -> UInt16 { throw HResult.Error.notImpl }
    public func getInt32() throws -> Int32 { throw HResult.Error.notImpl }
    public func getUInt32() throws -> UInt32 { throw HResult.Error.notImpl }
    public func getInt64() throws -> Int64 { throw HResult.Error.notImpl }
    public func getUInt64() throws -> UInt64 { throw HResult.Error.notImpl }
    public func getSingle() throws -> Float { throw HResult.Error.notImpl }
    public func getDouble() throws -> Double { throw HResult.Error.notImpl }
    public func getChar16() throws -> Char16 { throw HResult.Error.notImpl }
    public func getBoolean() throws -> Bool { throw HResult.Error.notImpl }
    public func getString() throws -> String { throw HResult.Error.notImpl }
    public func getGuid() throws -> UUID { throw HResult.Error.notImpl }
    public func getUInt8Array() throws -> [UInt8] { throw HResult.Error.notImpl }
    public func getInt16Array() throws -> [Int16] { throw HResult.Error.notImpl }
    public func getUInt16Array() throws -> [UInt16] { throw HResult.Error.notImpl }
    public func getInt32Array() throws -> [Int32] { throw HResult.Error.notImpl }
    public func getUInt32Array() throws -> [UInt32] { throw HResult.Error.notImpl }
    public func getInt64Array() throws -> [Int64] { throw HResult.Error.notImpl }
    public func getUInt64Array() throws -> [UInt64] { throw HResult.Error.notImpl }
    public func getSingleArray() throws -> [Float] { throw HResult.Error.notImpl }
    public func getDoubleArray() throws -> [Double] { throw HResult.Error.notImpl }
    public func getChar16Array() throws -> [Char16] { throw HResult.Error.notImpl }
    public func getBooleanArray() throws -> [Bool] { throw HResult.Error.notImpl }
    public func getStringArray() throws -> [String] { throw HResult.Error.notImpl }
    public func getInspectableArray() throws -> [IInspectable] { throw HResult.Error.notImpl }
    public func getGuidArray() throws -> [UUID] { throw HResult.Error.notImpl }
}