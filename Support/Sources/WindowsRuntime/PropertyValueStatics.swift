import COM
import WindowsRuntime_ABI
import struct Foundation.UUID

internal enum PropertyValueStatics {
    private static let iid = COMInterfaceID(0x629BDBC8, 0xD932, 0x4FF4, 0x96B9, 0x8D96C5C1E858)
    private static var lazyReference: COM.COMLazyReference<WindowsRuntime_ABI.SWRT_WindowsFoundation_IPropertyValueStatics> = .init()

    private static var this: UnsafeMutablePointer<WindowsRuntime_ABI.SWRT_WindowsFoundation_IPropertyValueStatics> {
        get throws {
            try lazyReference.getPointer {
                try WinRTClassLoader.default.getActivationFactory(
                    runtimeClass: "Windows.Foundation.PropertyValue",
                    interfaceID: iid)
            }
        }
    }

    public static func createUInt8(_ value: UInt8) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateUInt8(this, value, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createInt16(_ value: Int16) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateInt16(this, value, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createUInt16(_ value: UInt16) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateUInt16(this, value, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createInt32(_ value: Int32) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateInt32(this, value, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createUInt32(_ value: UInt32) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateUInt32(this, value, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createInt64(_ value: Int64) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateInt64(this, value, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createUInt64(_ value: UInt64) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateUInt64(this, value, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createSingle(_ value: Float) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateSingle(this, value, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createDouble(_ value: Double) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateDouble(this, value, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createChar16(_ value: Char16) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        let value = WinRTPrimitiveProjection.Char16.toABI(value)
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateChar16(this, value, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createBoolean(_ value: Bool) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateBoolean(this, value, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createString(_ value: String) throws -> COMReference<SWRT_IInspectable> {
        var value_abi = try WinRTPrimitiveProjection.String.toABI(value)
        defer { WinRTPrimitiveProjection.String.release(&value_abi) }
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateString(this, value_abi, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    public static func createGuid(_ value: UUID) throws -> COMReference<SWRT_IInspectable> {
        let value_abi = COM.GUIDProjection.toABI(value)
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.throwIfFailed(this.pointee.lpVtbl.pointee.CreateGuid(this, value_abi, &propertyValue))
        guard let propertyValue else { throw HResult.Error.pointer }
        return COMReference(transferringRef: propertyValue)
    }
}
