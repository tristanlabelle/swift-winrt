import COM
import WindowsRuntime_ABI

internal enum PropertyValueStatics {
    private static let iid = COMInterfaceID(0x629BDBC8, 0xD932, 0x4FF4, 0x96B9, 0x8D96C5C1E858)
    private static var lazyReference: COM.COMLazyReference<WindowsRuntime_ABI.SWRT_WindowsFoundation_IPropertyValueStatics> = .init()

    private static var this: UnsafeMutablePointer<WindowsRuntime_ABI.SWRT_WindowsFoundation_IPropertyValueStatics> {
        get throws {
            try lazyReference.getPointer {
                try SystemMetaclassResolver.getActivationFactory(
                    runtimeClass: "Windows.Foundation.PropertyValue",
                    interfaceID: iid)
            }
        }
    }

    public static func createUInt8(_ value: UInt8) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.CreateUInt8(this, value, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createInt16(_ value: Int16) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.CreateInt16(this, value, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createUInt16(_ value: UInt16) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.CreateUInt16(this, value, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createInt32(_ value: Int32) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.CreateInt32(this, value, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createUInt32(_ value: UInt32) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.CreateUInt32(this, value, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createInt64(_ value: Int64) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.CreateInt64(this, value, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createUInt64(_ value: UInt64) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.CreateUInt64(this, value, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createSingle(_ value: Float) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.CreateSingle(this, value, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createDouble(_ value: Double) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.CreateDouble(this, value, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createChar16(_ value: Char16) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        let value = PrimitiveProjection.Char16.toABI(value)
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.CreateChar16(this, value, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createBoolean(_ value: Bool) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.CreateBoolean(this, value, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createString(_ value: String) throws -> COMReference<SWRT_IInspectable> {
        var value_abi = try PrimitiveProjection.String.toABI(value)
        defer { PrimitiveProjection.String.release(&value_abi) }
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.CreateString(this, value_abi, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createGuid(_ value: GUID) throws -> COMReference<SWRT_IInspectable> {
        let value_abi = COM.GUIDProjection.toABI(value)
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.CreateGuid(this, value_abi, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createDateTime(_ value: WindowsFoundation_DateTime) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        let value_abi = WindowsFoundation_DateTime.toABI(value)
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.CreateDateTime(this, value_abi, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createTimeSpan(_ value: WindowsFoundation_TimeSpan) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        let value_abi = WindowsFoundation_TimeSpan.toABI(value)
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.CreateTimeSpan(this, value_abi, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createPoint(_ value: WindowsFoundation_Point) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        let value_abi = WindowsFoundation_Point.toABI(value)
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.CreatePoint(this, value_abi, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createSize(_ value: WindowsFoundation_Size) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        let value_abi = WindowsFoundation_Size.toABI(value)
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.CreateSize(this, value_abi, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createRect(_ value: WindowsFoundation_Rect) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        let value_abi = WindowsFoundation_Rect.toABI(value)
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.CreateRect(this, value_abi, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }
}
