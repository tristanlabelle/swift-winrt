/// Represents a value in a property store. You can't implement this interface, see Remarks.
public typealias WindowsFoundation_IPropertyValue = any WindowsFoundation_IPropertyValueProtocol

/// Represents a value in a property store. You can't implement this interface, see Remarks.
public protocol WindowsFoundation_IPropertyValueProtocol: IInspectableProtocol {
    /// Returns the type stored in the property value.
    var type: WindowsFoundation_PropertyType { get throws }

    /// Gets a value that indicates whether the property value is a scalar value.
    var isNumericScalar: Bool { get throws }

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
    func getGuid() throws -> GUID
    func getDateTime() throws -> WindowsFoundation_DateTime
    func getTimeSpan() throws -> WindowsFoundation_TimeSpan
    func getPoint() throws -> WindowsFoundation_Point
    func getSize() throws -> WindowsFoundation_Size
    func getRect() throws -> WindowsFoundation_Rect
    func getUInt8Array(_ value: inout [UInt8]) throws
    func getInt16Array(_ value: inout [Int16]) throws
    func getUInt16Array(_ value: inout [UInt16]) throws
    func getInt32Array(_ value: inout [Int32]) throws
    func getUInt32Array(_ value: inout [UInt32]) throws
    func getInt64Array(_ value: inout [Int64]) throws
    func getUInt64Array(_ value: inout [UInt64]) throws
    func getSingleArray(_ value: inout [Float]) throws
    func getDoubleArray(_ value: inout [Double]) throws
    func getChar16Array(_ value: inout [Char16]) throws
    func getBooleanArray(_ value: inout [Bool]) throws
    func getStringArray(_ value: inout [String]) throws
    func getInspectableArray(_ value: inout [IInspectable?]) throws
    func getGuidArray(_ value: inout [GUID]) throws
    func getDateTimeArray(_ value: inout [WindowsFoundation_DateTime]) throws
    func getTimeSpanArray(_ value: inout [WindowsFoundation_TimeSpan]) throws
    func getPointArray(_ value: inout [WindowsFoundation_Point]) throws
    func getSizeArray(_ value: inout [WindowsFoundation_Size]) throws
    func getRectArray(_ value: inout [WindowsFoundation_Rect]) throws
}

extension WindowsFoundation_IPropertyValueProtocol {
    /// Returns the type stored in the property value.
    var type_: WindowsFoundation_PropertyType { try! self.type }

    /// Gets a value that indicates whether the property value is a scalar value.
    var isNumericScalar_: Bool { try! self.isNumericScalar }

    public func getUInt8() throws -> UInt8 { throw COMError.notImpl }
    public func getInt16() throws -> Int16 { throw COMError.notImpl }
    public func getUInt16() throws -> UInt16 { throw COMError.notImpl }
    public func getInt32() throws -> Int32 { throw COMError.notImpl }
    public func getUInt32() throws -> UInt32 { throw COMError.notImpl }
    public func getInt64() throws -> Int64 { throw COMError.notImpl }
    public func getUInt64() throws -> UInt64 { throw COMError.notImpl }
    public func getSingle() throws -> Float { throw COMError.notImpl }
    public func getDouble() throws -> Double { throw COMError.notImpl }
    public func getChar16() throws -> Char16 { throw COMError.notImpl }
    public func getBoolean() throws -> Bool { throw COMError.notImpl }
    public func getString() throws -> String { throw COMError.notImpl }
    public func getGuid() throws -> GUID { throw COMError.notImpl }
    public func getDateTime() throws -> WindowsFoundation_DateTime { throw COMError.notImpl }
    public func getTimeSpan() throws -> WindowsFoundation_TimeSpan { throw COMError.notImpl }
    public func getPoint() throws -> WindowsFoundation_Point { throw COMError.notImpl }
    public func getSize() throws -> WindowsFoundation_Size { throw COMError.notImpl }
    public func getRect() throws -> WindowsFoundation_Rect { throw COMError.notImpl }
    public func getUInt8Array(_ value: inout [UInt8]) throws { throw COMError.notImpl }
    public func getInt16Array(_ value: inout [Int16]) throws { throw COMError.notImpl }
    public func getUInt16Array(_ value: inout [UInt16]) throws { throw COMError.notImpl }
    public func getInt32Array(_ value: inout [Int32]) throws { throw COMError.notImpl }
    public func getUInt32Array(_ value: inout [UInt32]) throws { throw COMError.notImpl }
    public func getInt64Array(_ value: inout [Int64]) throws { throw COMError.notImpl }
    public func getUInt64Array(_ value: inout [UInt64]) throws { throw COMError.notImpl }
    public func getSingleArray(_ value: inout [Float]) throws { throw COMError.notImpl }
    public func getDoubleArray(_ value: inout [Double]) throws { throw COMError.notImpl }
    public func getChar16Array(_ value: inout [Char16]) throws { throw COMError.notImpl }
    public func getBooleanArray(_ value: inout [Bool]) throws { throw COMError.notImpl }
    public func getStringArray(_ value: inout [String]) throws { throw COMError.notImpl }
    public func getInspectableArray(_ value: inout [IInspectable?]) throws { throw COMError.notImpl }
    public func getGuidArray(_ value: inout [GUID]) throws { throw COMError.notImpl }
    public func getDateTimeArray(_ value: inout [WindowsFoundation_DateTime]) throws { throw COMError.notImpl }
    public func getTimeSpanArray(_ value: inout [WindowsFoundation_TimeSpan]) throws { throw COMError.notImpl }
    public func getPointArray(_ value: inout [WindowsFoundation_Point]) throws { throw COMError.notImpl }
    public func getSizeArray(_ value: inout [WindowsFoundation_Size]) throws { throw COMError.notImpl }
    public func getRectArray(_ value: inout [WindowsFoundation_Rect]) throws { throw COMError.notImpl }
}

import SWRT_WindowsFoundation

internal func uuidof(_: SWRT_WindowsFoundation_IPropertyValue.Type) -> COMInterfaceID {
    .init(0x4BD682DD, 0x7554, 0x40E9, 0x9A9B, 0x82654EDE7E62)
}

extension COMInterop where ABIStruct == SWRT_WindowsFoundation_IPropertyValue {
    internal func get_Type() throws -> WindowsFoundation_PropertyType {
        var abi_value: SWRT_WindowsFoundation_PropertyType = .init()
        try WinRTError.fromABI(this.pointee.VirtualTable.pointee.get_Type(this, &abi_value))
        return WindowsFoundation_PropertyType.fromABI(abi_value)
    }

    internal func get_IsNumericScalar() throws -> Bool {
        var abi_value: CBool = false
        try WinRTError.fromABI(this.pointee.VirtualTable.pointee.get_IsNumericScalar(this, &abi_value))
        return abi_value
    }
}