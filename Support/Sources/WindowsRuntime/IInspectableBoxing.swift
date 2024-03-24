import WindowsRuntime_ABI
import struct Foundation.UUID

/// Provides helper methods to box and unbox primitive types, value types and delegates to IInspectable.
public enum IInspectableBoxing {
    private static func toSwift(_ inspectable: consuming COMReference<SWRT_IInspectable>) -> IInspectable {
        IInspectableProjection.toSwift(inspectable)
    }
}

// Primitives
extension IInspectableBoxing {
    public static func uint8(_ value: UInt8) throws -> IInspectable { try toSwift(PropertyValueStatics.createUInt8(value)) }
    public static func int16(_ value: Int16) throws -> IInspectable { try toSwift(PropertyValueStatics.createInt16(value)) }
    public static func uint16(_ value: UInt16) throws -> IInspectable { try toSwift(PropertyValueStatics.createUInt16(value)) }
    public static func int32(_ value: Int32) throws -> IInspectable { try toSwift(PropertyValueStatics.createInt32(value)) }
    public static func uint32(_ value: UInt32) throws -> IInspectable { try toSwift(PropertyValueStatics.createUInt32(value)) }
    public static func int64(_ value: Int64) throws -> IInspectable { try toSwift(PropertyValueStatics.createInt64(value)) }
    public static func uint64(_ value: UInt64) throws -> IInspectable { try toSwift(PropertyValueStatics.createUInt64(value)) }
    public static func single(_ value: Float) throws -> IInspectable { try toSwift(PropertyValueStatics.createSingle(value)) }
    public static func double(_ value: Double) throws -> IInspectable { try toSwift(PropertyValueStatics.createDouble(value)) }
    public static func char16(_ value: UTF16.CodeUnit) throws -> IInspectable { try toSwift(PropertyValueStatics.createChar16(value)) }
    public static func string(_ value: String) throws -> IInspectable { try toSwift(PropertyValueStatics.createString(value)) }
    public static func guid(_ value: UUID) throws -> IInspectable { try toSwift(PropertyValueStatics.createGuid(value)) }

    private static func unboxPrimitive<ABIValue>(_ inspectable: IInspectable, ireferenceID: COMInterfaceID) -> ABIValue? {
        do {
            let ireference = try inspectable._queryInterface(ireferenceID).reinterpret(to: SWRT_WindowsFoundation_IReference.self)
            return try withUnsafeTemporaryAllocation(of: ABIValue.self, capacity: 1) {
                let valuePointer = $0.baseAddress
                try WinRTError.throwIfFailed(ireference.pointer.pointee.lpVtbl.pointee.get_Value(ireference.pointer, valuePointer))
                return valuePointer!.pointee
            }
        }
        catch {
            return nil
        }
    }

    public static func asUInt8(_ inspectable: IInspectable) -> UInt8? {
        unboxPrimitive(inspectable, ireferenceID: PropertyValueStatics.IReferenceIDs.uint8)
    }
    public static func asInt16(_ inspectable: IInspectable) -> Int16? {
        unboxPrimitive(inspectable, ireferenceID: PropertyValueStatics.IReferenceIDs.int16)
    }
    public static func asUInt16(_ inspectable: IInspectable) -> UInt16? {
        unboxPrimitive(inspectable, ireferenceID: PropertyValueStatics.IReferenceIDs.uint16)
    }
    public static func asInt32(_ inspectable: IInspectable) -> Int32? {
        unboxPrimitive(inspectable, ireferenceID: PropertyValueStatics.IReferenceIDs.int32)
    }
    public static func asUInt32(_ inspectable: IInspectable) -> UInt32? {
        unboxPrimitive(inspectable, ireferenceID: PropertyValueStatics.IReferenceIDs.uint32)
    }
    public static func asInt64(_ inspectable: IInspectable) -> Int64? {
        unboxPrimitive(inspectable, ireferenceID: PropertyValueStatics.IReferenceIDs.int64)
    }
    public static func asUInt64(_ inspectable: IInspectable) -> UInt64? {
        unboxPrimitive(inspectable, ireferenceID: PropertyValueStatics.IReferenceIDs.uint64)
    }
    public static func asSingle(_ inspectable: IInspectable) -> Float? {
        unboxPrimitive(inspectable, ireferenceID: PropertyValueStatics.IReferenceIDs.single)
    }
    public static func asDouble(_ inspectable: IInspectable) -> Double? {
        unboxPrimitive(inspectable, ireferenceID: PropertyValueStatics.IReferenceIDs.double)
    }
    public static func asChar16(_ inspectable: IInspectable) -> UTF16.CodeUnit? {
        unboxPrimitive(inspectable, ireferenceID: PropertyValueStatics.IReferenceIDs.char16)
    }
    public static func asString(_ inspectable: IInspectable) -> String? {
        guard var hstring: SWRT_HString? = unboxPrimitive(inspectable, ireferenceID: PropertyValueStatics.IReferenceIDs.string) else { return nil }
        return HStringProjection.toSwift(consuming: &hstring)
    }
    public static func asGuid(_ inspectable: IInspectable) -> UUID? {
        guard var guid: SWRT_Guid = unboxPrimitive(inspectable, ireferenceID: PropertyValueStatics.IReferenceIDs.guid) else { return nil }
        return COM.GUIDProjection.toSwift(consuming: &guid)
    }
}
