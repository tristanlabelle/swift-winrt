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

    internal enum IReferenceIDs {
        public static var bool: COMInterfaceID { COMInterfaceID(0x3C00FD60, 0x2950, 0x5939, 0xA21A, 0x2D12C5A01B8A) }
        public static var uint8: COMInterfaceID { COMInterfaceID(0xE5198CC8, 0x2873, 0x55F5, 0xB0A1, 0x84FF9E4AAD62) }
        public static var int16: COMInterfaceID { COMInterfaceID(0x6EC9E41B, 0x6709, 0x5647, 0x9918, 0xA1270110FC4E) }
        public static var uint16: COMInterfaceID { COMInterfaceID(0x5AB7D2C3, 0x6B62, 0x5E71, 0xA4B6, 0x2D49C4F238FD) }
        public static var int32: COMInterfaceID { COMInterfaceID(0x548CEFBD, 0xBC8A, 0x5FA0, 0x8DF2, 0x957440FC8BF4) }
        public static var uint32: COMInterfaceID { COMInterfaceID(0x513EF3AF, 0xE784, 0x5325, 0xA91E, 0x97C2B8111CF3) }
        public static var int64: COMInterfaceID { COMInterfaceID(0x4DDA9E24, 0xE69F, 0x5C6A, 0xA0A6, 0x93427365AF2A) }
        public static var uint64: COMInterfaceID { COMInterfaceID(0x6755E376, 0x53BB, 0x568B, 0xA11D, 0x17239868309E) }
        public static var single: COMInterfaceID { COMInterfaceID(0x719CC2BA, 0x3E76, 0x5DEF, 0x9F1A, 0x38D85A145EA8) }
        public static var double: COMInterfaceID { COMInterfaceID(0x2F2D6C29, 0x5473, 0x5F3E, 0x92E7, 0x96572BB990E2) }
        public static var char16: COMInterfaceID { COMInterfaceID(0xFB393EF3, 0xBBAC, 0x5BD5, 0x9144, 0x84F23576F415) }
        public static var string: COMInterfaceID { COMInterfaceID(0xFD416DFB, 0x2A07, 0x52EB, 0xAAE3, 0xDFCE14116C05) }
        public static var guid: COMInterfaceID { COMInterfaceID(0x7D50F649, 0x632C, 0x51F9, 0x849A, 0xEE49428933EA) }
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

    public static func createChar16(_ value: UInt16) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
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
        var value_abi = try HStringProjection.toABI(value)
        defer { HStringProjection.release(&value_abi) }
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
