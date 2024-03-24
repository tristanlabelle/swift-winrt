import COM
import WindowsRuntime_ABI
import struct Foundation.UUID

extension WindowsFoundation_IReferenceProjection {
    public enum Boolean: IReferencePrimitiveProjection {
        public typealias SwiftObject = Swift.Bool
        public static var interfaceID: COMInterfaceID { PropertyValueStatics.IReferenceIDs.boolean }
        internal static func box(_ value: SwiftObject) throws -> COMReference<SWRT_IInspectable> { try PropertyValueStatics.createBoolean(value) }
        public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject { getABIValue(reference.pointer) }
    }

    public enum UInt8: IReferencePrimitiveProjection {
        public typealias SwiftObject = Swift.UInt8
        public static var interfaceID: COMInterfaceID { PropertyValueStatics.IReferenceIDs.uint8 }
        internal static func box(_ value: SwiftObject) throws -> COMReference<SWRT_IInspectable> { try PropertyValueStatics.createUInt8(value) }
        public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject { getABIValue(reference.pointer) }
    }

    public enum Int16: IReferencePrimitiveProjection {
        public typealias SwiftObject = Swift.Int16
        public static var interfaceID: COMInterfaceID { PropertyValueStatics.IReferenceIDs.int16 }
        internal static func box(_ value: SwiftObject) throws -> COMReference<SWRT_IInspectable> { try PropertyValueStatics.createInt16(value) }
        public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject { getABIValue(reference.pointer) }
    }

    public enum UInt16: IReferencePrimitiveProjection {
        public typealias SwiftObject = Swift.UInt16
        public static var interfaceID: COMInterfaceID { PropertyValueStatics.IReferenceIDs.uint16 }
        internal static func box(_ value: SwiftObject) throws -> COMReference<SWRT_IInspectable> { try PropertyValueStatics.createUInt16(value) }
        public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject { getABIValue(reference.pointer) }
    }

    public enum Int32: IReferencePrimitiveProjection {
        public typealias SwiftObject = Swift.Int32
        public static var interfaceID: COMInterfaceID { PropertyValueStatics.IReferenceIDs.int32 }
        internal static func box(_ value: SwiftObject) throws -> COMReference<SWRT_IInspectable> { try PropertyValueStatics.createInt32(value) }
        public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject { getABIValue(reference.pointer) }
    }

    public enum UInt32: IReferencePrimitiveProjection {
        public typealias SwiftObject = Swift.UInt32
        public static var interfaceID: COMInterfaceID { PropertyValueStatics.IReferenceIDs.uint32 }
        internal static func box(_ value: SwiftObject) throws -> COMReference<SWRT_IInspectable> { try PropertyValueStatics.createUInt32(value) }
        public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject { getABIValue(reference.pointer) }
    }

    public enum Int64: IReferencePrimitiveProjection {
        public typealias SwiftObject = Swift.Int64
        public static var interfaceID: COMInterfaceID { PropertyValueStatics.IReferenceIDs.int64 }
        internal static func box(_ value: SwiftObject) throws -> COMReference<SWRT_IInspectable> { try PropertyValueStatics.createInt64(value) }
        public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject { getABIValue(reference.pointer) }
    }

    public enum UInt64: IReferencePrimitiveProjection {
        public typealias SwiftObject = Swift.UInt64
        public static var interfaceID: COMInterfaceID { PropertyValueStatics.IReferenceIDs.uint64 }
        internal static func box(_ value: SwiftObject) throws -> COMReference<SWRT_IInspectable> { try PropertyValueStatics.createUInt64(value) }
        public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject { getABIValue(reference.pointer) }
    }

    public enum Single: IReferencePrimitiveProjection {
        public typealias SwiftObject = Swift.Float
        public static var interfaceID: COMInterfaceID { PropertyValueStatics.IReferenceIDs.single }
        internal static func box(_ value: SwiftObject) throws -> COMReference<SWRT_IInspectable> { try PropertyValueStatics.createSingle(value) }
        public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject { getABIValue(reference.pointer) }
    }

    public enum Double: IReferencePrimitiveProjection {
        public typealias SwiftObject = Swift.Double
        public static var interfaceID: COMInterfaceID { PropertyValueStatics.IReferenceIDs.double }
        internal static func box(_ value: SwiftObject) throws -> COMReference<SWRT_IInspectable> { try PropertyValueStatics.createDouble(value) }
        public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject { getABIValue(reference.pointer) }
    }

    public enum Char16: IReferencePrimitiveProjection {
        public typealias SwiftObject = WindowsRuntime.Char16
        public static var interfaceID: COMInterfaceID { PropertyValueStatics.IReferenceIDs.char16 }
        internal static func box(_ value: SwiftObject) throws -> COMReference<SWRT_IInspectable> { try PropertyValueStatics.createChar16(value) }
        public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject { Char16Projection.toSwift(getABIValue(reference.pointer)) }
    }

    public enum String: IReferencePrimitiveProjection {
        public typealias SwiftObject = Swift.String
        public static var interfaceID: COMInterfaceID { PropertyValueStatics.IReferenceIDs.string }
        internal static func box(_ value: SwiftObject) throws -> COMReference<SWRT_IInspectable> { try PropertyValueStatics.createString(value) }
        public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject { HStringProjection.toSwift(getABIValue(reference.pointer)) }
    }

    public enum Guid: IReferencePrimitiveProjection {
        public typealias SwiftObject = UUID
        public static var interfaceID: COMInterfaceID { PropertyValueStatics.IReferenceIDs.guid }
        internal static func box(_ value: SwiftObject) throws -> COMReference<SWRT_IInspectable> { try PropertyValueStatics.createGuid(value) }
        public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject { GUIDProjection.toSwift(getABIValue(reference.pointer)) }
    }
}

fileprivate protocol IReferencePrimitiveProjection: COMProjection
        where COMInterface == WindowsRuntime_ABI.SWRT_WindowsFoundation_IReference,
        COMVirtualTable == WindowsRuntime_ABI.SWRT_WindowsFoundation_IReferenceVTable {
    static func box(_ value: SwiftObject) throws -> COMReference<SWRT_IInspectable>
}

extension IReferencePrimitiveProjection {
    public static var abiDefaultValue: ABIValue { nil }

    public static func toCOM(_ value: SwiftObject) throws -> COMReference<COMInterface> {
        let inspectable = try box(value)
        return try inspectable.interop.queryInterface(Self.interfaceID)
            .reinterpret(to: WindowsRuntime_ABI.SWRT_WindowsFoundation_IReference.self)
    }

    public static func release(_ value: inout ABIValue) {
        guard let comPointer = value else { return }
        COMInterop(comPointer).release()
        value = nil
    }
}

fileprivate func getABIValue<ABIValue>(
        _ pointer: UnsafeMutablePointer<SWRT_WindowsFoundation_IReference>) -> ABIValue {
    return withUnsafeTemporaryAllocation(of: ABIValue.self, capacity: 1) { bufferPointer in
        let abiValuePointer = bufferPointer.baseAddress!
        try! HResult.throwIfFailed(pointer.pointee.lpVtbl.pointee.get_Value(pointer, abiValuePointer))
        return abiValuePointer.pointee
    }
}