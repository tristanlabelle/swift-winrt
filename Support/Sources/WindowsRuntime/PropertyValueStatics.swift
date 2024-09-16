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
        try create(value, binding: Char16Binding.self, factory: virtualTable.pointee.CreateChar16)
    }

    public static func createBoolean(_ value: Bool) throws -> COMReference<SWRT_IInspectable> {
        try create(value, factory: virtualTable.pointee.CreateBoolean)
    }

    public static func createString(_ value: String) throws -> COMReference<SWRT_IInspectable> {
        try create(value, binding: StringBinding.self, factory: virtualTable.pointee.CreateString)
    }

    public static func createGuid(_ value: GUID) throws -> COMReference<SWRT_IInspectable> {
        try create(value, binding: GuidBinding.self, factory: virtualTable.pointee.CreateGuid)
    }

    public static func createDateTime(_ value: WindowsFoundation_DateTime) throws -> COMReference<SWRT_IInspectable> {
        try create(value, binding: WindowsFoundation_DateTime.self, factory: virtualTable.pointee.CreateDateTime)
    }

    public static func createTimeSpan(_ value: WindowsFoundation_TimeSpan) throws -> COMReference<SWRT_IInspectable> {
        try create(value, binding: WindowsFoundation_TimeSpan.self, factory: virtualTable.pointee.CreateTimeSpan)
    }

    public static func createPoint(_ value: WindowsFoundation_Point) throws -> COMReference<SWRT_IInspectable> {
        try create(value, binding: WindowsFoundation_Point.self, factory: virtualTable.pointee.CreatePoint)
    }

    public static func createSize(_ value: WindowsFoundation_Size) throws -> COMReference<SWRT_IInspectable> {
        try create(value, binding: WindowsFoundation_Size.self, factory: virtualTable.pointee.CreateSize)
    }

    public static func createRect(_ value: WindowsFoundation_Rect) throws -> COMReference<SWRT_IInspectable> {
        try create(value, binding: WindowsFoundation_Rect.self, factory: virtualTable.pointee.CreateRect)
    }

    public static func createUInt8Array(_ value: [UInt8]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, elementBinding: UInt8Binding.self, abiCompatible: true,
            factory: virtualTable.pointee.CreateUInt8Array)
    }

    public static func createInt16Array(_ value: [Int16]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, elementBinding: Int16Binding.self, abiCompatible: true,
            factory: virtualTable.pointee.CreateInt16Array)
    }

    public static func createUInt16Array(_ value: [UInt16]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, elementBinding: UInt16Binding.self, abiCompatible: true,
            factory: virtualTable.pointee.CreateUInt16Array)
    }

    public static func createInt32Array(_ value: [Int32]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, elementBinding: Int32Binding.self, abiCompatible: true,
            factory: virtualTable.pointee.CreateInt32Array)
    }

    public static func createUInt32Array(_ value: [UInt32]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, elementBinding: UInt32Binding.self, abiCompatible: true,
            factory: virtualTable.pointee.CreateUInt32Array)
    }

    public static func createInt64Array(_ value: [Int64]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, elementBinding: Int64Binding.self, abiCompatible: true,
            factory: virtualTable.pointee.CreateInt64Array)
    }

    public static func createUInt64Array(_ value: [UInt64]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, elementBinding: UInt64Binding.self, abiCompatible: true,
            factory: virtualTable.pointee.CreateUInt64Array)
    }

    public static func createSingleArray(_ value: [Float]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, elementBinding: SingleBinding.self, abiCompatible: true,
            factory: virtualTable.pointee.CreateSingleArray)
    }

    public static func createDoubleArray(_ value: [Double]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, elementBinding: DoubleBinding.self, abiCompatible: true,
            factory: virtualTable.pointee.CreateDoubleArray)
    }

    public static func createChar16Array(_ value: [Char16]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, elementBinding: Char16Binding.self, abiCompatible: true,
            factory: virtualTable.pointee.CreateChar16Array)
    }

    public static func createBooleanArray(_ value: [Bool]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, elementBinding: BooleanBinding.self, abiCompatible: true,
            factory: virtualTable.pointee.CreateBooleanArray)
    }

    public static func createStringArray(_ value: [String]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, elementBinding: StringBinding.self, abiCompatible: false,
            factory: virtualTable.pointee.CreateStringArray)
    }

    public static func createGuidArray(_ value: [GUID]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, elementBinding: GuidBinding.self, abiCompatible: true,
            factory: virtualTable.pointee.CreateGuidArray)
    }

    public static func createDateTimeArray(_ value: [WindowsFoundation_DateTime]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, elementBinding: WindowsFoundation_DateTime.self, abiCompatible: true,
            factory: virtualTable.pointee.CreateDateTimeArray)
    }

    public static func createTimeSpanArray(_ value: [WindowsFoundation_TimeSpan]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, elementBinding: WindowsFoundation_TimeSpan.self, abiCompatible: true,
            factory: virtualTable.pointee.CreateTimeSpanArray)
    }

    public static func createPointArray(_ value: [WindowsFoundation_Point]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, elementBinding: WindowsFoundation_Point.self, abiCompatible: true,
            factory: virtualTable.pointee.CreatePointArray)
    }

    public static func createSizeArray(_ value: [WindowsFoundation_Size]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, elementBinding: WindowsFoundation_Size.self, abiCompatible: true,
            factory: virtualTable.pointee.CreateSizeArray)
    }

    public static func createRectArray(_ value: [WindowsFoundation_Rect]) throws -> COMReference<SWRT_IInspectable> {
        try createArray(
            value, elementBinding: WindowsFoundation_Rect.self, abiCompatible: true,
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

    private static func create<Binding: ABIBinding>(
            _ value: Binding.SwiftValue,
            binding: Binding.Type,
            factory: SingleValueFactory<Binding.ABIValue>) throws -> COMReference<SWRT_IInspectable> {
        var value_abi = try binding.toABI(value)
        defer { binding.release(&value_abi) }
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

    private static func createArray<ElementBinding: ABIBinding>(
            _ value: [ElementBinding.SwiftValue],
            elementBinding: ElementBinding.Type,
            abiCompatible: Bool,
            factory: ArrayFactory<ElementBinding.ABIValue>) throws -> COMReference<SWRT_IInspectable> {
        var propertyValue: IInspectablePointer? = nil

        // Attempt to use the provided array in-place
        if abiCompatible, MemoryLayout<ElementBinding.SwiftValue>.size == MemoryLayout<ElementBinding.ABIValue>.size {
            try value.withUnsafeBufferPointer { bufferPointer in
                let abiPointer = bufferPointer.baseAddress.map { UnsafePointer<ElementBinding.ABIValue>(OpaquePointer($0)) }
                try WinRTError.fromABI(factory(this, UInt32(bufferPointer.count), UnsafeMutablePointer(mutating: abiPointer), &propertyValue))
            }
        }
        else {
            var value_abi = try ArrayBinding<ElementBinding>.toABI(value)
            defer { ArrayBinding<ElementBinding>.release(&value_abi) }
            try WinRTError.fromABI(factory(this, value_abi.count, value_abi.pointer, &propertyValue))
        }

        guard let propertyValue else { throw COMError.pointer }
        return COMReference(transferringRef: propertyValue)
    }

    internal static func createIReference<ValueBinding: IReferenceableBinding>(
            _ value: ValueBinding.SwiftValue,
            valueBinding: ValueBinding.Type,
            factory: (ValueBinding.SwiftValue) throws -> COMReference<SWRT_IInspectable>)
            throws -> WindowsFoundation_IReference<ValueBinding.SwiftValue> {
        try WindowsFoundation_IReferenceBinding<ValueBinding>.toSwift(
            factory(value).queryInterface(ValueBinding.ireferenceID, type: SWRT_WindowsFoundation_IReference.self))
    }

    internal static func createIReferenceArray<ValueBinding: IReferenceableBinding>(
            _ array: [ValueBinding.SwiftValue],
            valueBinding: ValueBinding.Type,
            factory: ([ValueBinding.SwiftValue]) throws -> COMReference<SWRT_IInspectable>)
            throws -> WindowsFoundation_IReferenceArray<ValueBinding.SwiftValue> {
        try WindowsFoundation_IReferenceArrayBinding<ValueBinding>.toSwift(
            factory(array).queryInterface(ValueBinding.ireferenceArrayID, type: SWRT_WindowsFoundation_IReferenceArray.self))
    }
}
