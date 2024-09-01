import COM
import WindowsRuntime_ABI
import SWRT_WindowsFoundation

/// Exposes static factory methods from `Windows.Foundation.PropertyValue`,
/// which are used to box primitive types and known `Windows.Foundation` structs to `IReference<T>`/`IInspectable`.
internal enum PropertyValueStatics {
    private static let iid = COMInterfaceID(0x629BDBC8, 0xD932, 0x4FF4, 0x96B9, 0x8D96C5C1E858)
    private static var lazyReference: COM.COMReference<SWRT_WindowsFoundation_IPropertyValueStatics>.Optional = .none

    private static var this: UnsafeMutablePointer<SWRT_WindowsFoundation_IPropertyValueStatics> {
        get throws {
            try lazyReference.lazyInitPointer {
                try SystemActivationFactoryResolver.resolve(
                    runtimeClass: "Windows.Foundation.PropertyValue",
                    interfaceID: iid)
            }
        }
    }

    private static var virtualTable: UnsafeMutablePointer<SWRT_WindowsFoundation_IPropertyValueStatics_VirtualTable> {
        get throws { try this.pointee.VirtualTable }
    }

    public static func createUInt8(_ value: UInt8) throws -> COMReference<SWRT_IInspectable> {
        try create(value, factory: virtualTable.pointee.CreateUInt8)
    }

    public static func createInt16(_ value: Int16) throws -> COMReference<SWRT_IInspectable> {
        try create(value, factory: virtualTable.pointee.CreateInt16)
    }

    public static func createUInt16(_ value: UInt16) throws -> COMReference<SWRT_IInspectable> {
        try create(value, factory: virtualTable.pointee.CreateUInt16)
    }

    public static func createInt32(_ value: Int32) throws -> COMReference<SWRT_IInspectable> {
        try create(value, factory: virtualTable.pointee.CreateInt32)
    }

    public static func createUInt32(_ value: UInt32) throws -> COMReference<SWRT_IInspectable> {
        try create(value, factory: virtualTable.pointee.CreateUInt32)
    }

    public static func createInt64(_ value: Int64) throws -> COMReference<SWRT_IInspectable> {
        try create(value, factory: virtualTable.pointee.CreateInt64)
    }

    public static func createUInt64(_ value: UInt64) throws -> COMReference<SWRT_IInspectable> {
        try create(value, factory: virtualTable.pointee.CreateUInt64)
    }

    public static func createSingle(_ value: Float) throws -> COMReference<SWRT_IInspectable> {
        try create(value, factory: virtualTable.pointee.CreateSingle)
    }

    public static func createDouble(_ value: Double) throws -> COMReference<SWRT_IInspectable> {
        try create(value, factory: virtualTable.pointee.CreateDouble)
    }

    public static func createChar16(_ value: Char16) throws -> COMReference<SWRT_IInspectable> {
        try create(value, projection: Char16Projection.self, factory: virtualTable.pointee.CreateChar16)
    }

    public static func createBoolean(_ value: Bool) throws -> COMReference<SWRT_IInspectable> {
        try create(value, factory: virtualTable.pointee.CreateBoolean)
    }

    public static func createString(_ value: String) throws -> COMReference<SWRT_IInspectable> {
        try create(value, projection: StringProjection.self, factory: virtualTable.pointee.CreateString)
    }

    public static func createGuid(_ value: GUID) throws -> COMReference<SWRT_IInspectable> {
        try create(value, projection: GuidProjection.self, factory: virtualTable.pointee.CreateGuid)
    }

    public static func createDateTime(_ value: WindowsFoundation_DateTime) throws -> COMReference<SWRT_IInspectable> {
        try create(value, projection: WindowsFoundation_DateTime.self, factory: virtualTable.pointee.CreateDateTime)
    }

    public static func createTimeSpan(_ value: WindowsFoundation_TimeSpan) throws -> COMReference<SWRT_IInspectable> {
        try create(value, projection: WindowsFoundation_TimeSpan.self, factory: virtualTable.pointee.CreateTimeSpan)
    }

    public static func createPoint(_ value: WindowsFoundation_Point) throws -> COMReference<SWRT_IInspectable> {
        try create(value, projection: WindowsFoundation_Point.self, factory: virtualTable.pointee.CreatePoint)
    }

    public static func createSize(_ value: WindowsFoundation_Size) throws -> COMReference<SWRT_IInspectable> {
        try create(value, projection: WindowsFoundation_Size.self, factory: virtualTable.pointee.CreateSize)
    }

    public static func createRect(_ value: WindowsFoundation_Rect) throws -> COMReference<SWRT_IInspectable> {
        try create(value, projection: WindowsFoundation_Rect.self, factory: virtualTable.pointee.CreateRect)
    }

    public static func createUInt8Array(_ value: [UInt8]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, projection: UInt8Projection.self, inertProjection: true,
            factory: virtualTable.pointee.CreateUInt8Array)
    }

    public static func createInt16Array(_ value: [Int16]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, projection: Int16Projection.self, inertProjection: true,
            factory: virtualTable.pointee.CreateInt16Array)
    }

    public static func createUInt16Array(_ value: [UInt16]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, projection: UInt16Projection.self, inertProjection: true,
            factory: virtualTable.pointee.CreateUInt16Array)
    }

    public static func createInt32Array(_ value: [Int32]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, projection: Int32Projection.self, inertProjection: true,
            factory: virtualTable.pointee.CreateInt32Array)
    }

    public static func createUInt32Array(_ value: [UInt32]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, projection: UInt32Projection.self, inertProjection: true,
            factory: virtualTable.pointee.CreateUInt32Array)
    }

    public static func createInt64Array(_ value: [Int64]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, projection: Int64Projection.self, inertProjection: true,
            factory: virtualTable.pointee.CreateInt64Array)
    }

    public static func createUInt64Array(_ value: [UInt64]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, projection: UInt64Projection.self, inertProjection: true,
            factory: virtualTable.pointee.CreateUInt64Array)
    }

    public static func createSingleArray(_ value: [Float]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, projection: SingleProjection.self, inertProjection: true,
            factory: virtualTable.pointee.CreateSingleArray)
    }

    public static func createDoubleArray(_ value: [Double]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, projection: DoubleProjection.self, inertProjection: true,
            factory: virtualTable.pointee.CreateDoubleArray)
    }

    public static func createChar16Array(_ value: [Char16]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, projection: Char16Projection.self, inertProjection: true,
            factory: virtualTable.pointee.CreateChar16Array)
    }

    public static func createBooleanArray(_ value: [Bool]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, projection: BooleanProjection.self, inertProjection: true,
            factory: virtualTable.pointee.CreateBooleanArray)
    }

    public static func createStringArray(_ value: [String]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, projection: StringProjection.self, inertProjection: false,
            factory: virtualTable.pointee.CreateStringArray)
    }

    public static func createGuidArray(_ value: [GUID]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, projection: GuidProjection.self, inertProjection: true,
            factory: virtualTable.pointee.CreateGuidArray)
    }

    public static func createDateTimeArray(_ value: [WindowsFoundation_DateTime]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, projection: WindowsFoundation_DateTime.self, inertProjection: true,
            factory: virtualTable.pointee.CreateDateTimeArray)
    }

    public static func createTimeSpanArray(_ value: [WindowsFoundation_TimeSpan]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, projection: WindowsFoundation_TimeSpan.self, inertProjection: true,
            factory: virtualTable.pointee.CreateTimeSpanArray)
    }

    public static func createPointArray(_ value: [WindowsFoundation_Point]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, projection: WindowsFoundation_Point.self, inertProjection: true,
            factory: virtualTable.pointee.CreatePointArray)
    }

    public static func createSizeArray(_ value: [WindowsFoundation_Size]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, projection: WindowsFoundation_Size.self, inertProjection: true,
            factory: virtualTable.pointee.CreateSizeArray)
    }

    public static func createRectArray(_ value: [WindowsFoundation_Rect]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, projection: WindowsFoundation_Rect.self, inertProjection: true,
            factory: virtualTable.pointee.CreateRectArray)
    }

    // An IPropertyValueStatics.Create*** function type
    private typealias SingleValueFactory<ABIValue> = (
        _ this: UnsafeMutablePointer<SWRT_WindowsFoundation_IPropertyValueStatics>?,
        _ value: ABIValue,
        _ propertyValue: UnsafeMutablePointer<IInspectablePointer?>?)
        -> SWRT_HResult

    private static func create<ABIValue>(_ value: ABIValue, factory: SingleValueFactory<ABIValue>) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.fromABI(factory(this, value, &propertyValue))
        guard let propertyValue else { throw COMError.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    private static func create<Projection: ABIProjection>(
            _ value: Projection.SwiftValue,
            projection: Projection.Type,
            factory: SingleValueFactory<Projection.ABIValue>) throws -> COMReference<SWRT_IInspectable> {
        var value_abi = try projection.toABI(value)
        defer { projection.release(&value_abi) }
        var propertyValue: IInspectablePointer? = nil
        try WinRTError.fromABI(factory(this, value_abi, &propertyValue))
        guard let propertyValue else { throw COMError.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    // An IPropertyValueStatics.Create***Array function type
    private typealias ArrayFactory<ABIValue> = (
        _ this: UnsafeMutablePointer<SWRT_WindowsFoundation_IPropertyValueStatics>?,
        _ length: UInt32,
        _ pointer: UnsafeMutablePointer<ABIValue>?,
        _ propertyValue: UnsafeMutablePointer<IInspectablePointer?>?)
        -> SWRT_HResult

    private static func createArray<Projection: ABIProjection>(
            _ value: [Projection.SwiftValue],
            projection: Projection.Type,
            inertProjection: Bool,
            factory: ArrayFactory<Projection.ABIValue>) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil

        // Attempt to use the provided array in-place
        if inertProjection, MemoryLayout<Projection.SwiftValue>.size == MemoryLayout<Projection.ABIValue>.size {
            try value.withUnsafeBufferPointer { bufferPointer in
                let abiPointer = bufferPointer.baseAddress.map { UnsafePointer<Projection.ABIValue>(OpaquePointer($0)) }
                try WinRTError.fromABI(factory(this, UInt32(bufferPointer.count), UnsafeMutablePointer(mutating: abiPointer), &propertyValue))
            }
        }
        else {
            var value_abi = try ArrayProjection<Projection>.toABI(value)
            defer { ArrayProjection<Projection>.release(&value_abi) }
            try WinRTError.fromABI(factory(this, value_abi.count, value_abi.pointer, &propertyValue))
        }

        guard let propertyValue else { throw COMError.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    internal static func createIReference<Projection: IReferenceableProjection>(
            _ value: Projection.SwiftValue,
            projection: Projection.Type,
            factory: (Projection.SwiftValue) throws -> COMReference<SWRT_IInspectable>)
            throws -> WindowsFoundation_IReference<Projection.SwiftValue> {
        try WindowsFoundation_IReferenceProjection<Projection>.toSwift(
            factory(value).queryInterface(Projection.ireferenceID, type: SWRT_WindowsFoundation_IReference.self))
    }

    internal static func createIReferenceArray<Projection: IReferenceableProjection>(
            _ value: [Projection.SwiftValue],
            projection: Projection.Type,
            factory: ([Projection.SwiftValue]) throws -> COMReference<SWRT_IInspectable>)
            throws -> WindowsFoundation_IReferenceArray<Projection.SwiftValue> {
        try WindowsFoundation_IReferenceArrayProjection<Projection>.toSwift(
            factory(value).queryInterface(Projection.ireferenceArrayID, type: SWRT_WindowsFoundation_IReferenceArray.self))
    }
}
