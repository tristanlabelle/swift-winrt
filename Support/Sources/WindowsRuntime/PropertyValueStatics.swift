import COM
import WindowsRuntime_ABI
import struct Foundation.UUID

#if swift(>=5.10)
extension WindowsRuntime_ABI.SWRT_IPropertyValueStatics: @retroactive COMIUnknownStruct {}
#endif

extension WindowsRuntime_ABI.SWRT_IPropertyValueStatics: /* @retroactive */ COMIInspectableStruct {
    public static let iid = COMInterfaceID(0x629BDBC8, 0xD932, 0x4FF4, 0x96B9, 0x8D96C5C1E858)
}

extension COMInterop where Interface == WindowsRuntime_ABI.SWRT_IPropertyValueStatics {
    // Special case to return the raw pointer since these act as factory methods
    public func createUInt8(_ value: UInt8) throws -> IInspectablePointer? {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateUInt8(this, value, &propertyValue))
        return propertyValue
    }

    public func createInt16(_ value: Int16) throws -> IInspectablePointer? {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateInt16(this, value, &propertyValue))
        return propertyValue
    }

    public func createUInt16(_ value: UInt16) throws -> IInspectablePointer? {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateUInt16(this, value, &propertyValue))
        return propertyValue
    }

    public func createInt32(_ value: Int32) throws -> IInspectablePointer? {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateInt32(this, value, &propertyValue))
        return propertyValue
    }

    public func createUInt32(_ value: UInt32) throws -> IInspectablePointer? {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateUInt32(this, value, &propertyValue))
        return propertyValue
    }

    public func createInt64(_ value: Int64) throws -> IInspectablePointer? {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateInt64(this, value, &propertyValue))
        return propertyValue
    }

    public func createUInt64(_ value: UInt64) throws -> IInspectablePointer? {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateUInt64(this, value, &propertyValue))
        return propertyValue
    }

    public func createSingle(_ value: Float) throws -> IInspectablePointer? {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateSingle(this, value, &propertyValue))
        return propertyValue
    }

    public func createDouble(_ value: Double) throws -> IInspectablePointer? {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateDouble(this, value, &propertyValue))
        return propertyValue
    }

    public func createChar16(_ value: UInt16) throws -> IInspectablePointer? {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateChar16(this, value, &propertyValue))
        return propertyValue
    }

    public func createBoolean(_ value: Bool) throws -> IInspectablePointer? {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateBoolean(this, value, &propertyValue))
        return propertyValue
    }

    public func createString(_ value: String) throws -> IInspectablePointer? {
        var value_abi = try HStringProjection.toABI(value)
        defer { HStringProjection.release(&value_abi) }
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateString(this, value_abi, &propertyValue))
        return propertyValue
    }

    public func createGuid(_ value: UUID) throws -> IInspectablePointer? {
        let value_abi = COM.GUIDProjection.toABI(value)
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateGuid(this, value_abi, &propertyValue))
        return propertyValue
    }
}