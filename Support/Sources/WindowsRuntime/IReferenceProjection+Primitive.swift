import COM
import WindowsRuntime_ABI
import struct Foundation.UUID

extension IReferenceProjection {
    public typealias Bool = Primitive<BoolProjection>
    public typealias UInt8 = Primitive<NumericProjection<Swift.UInt8>>
    public typealias Int16 = Primitive<NumericProjection<Swift.Int16>>
    public typealias UInt16 = Primitive<NumericProjection<Swift.UInt16>>
    public typealias Int32 = Primitive<NumericProjection<Swift.Int32>>
    public typealias UInt32 = Primitive<NumericProjection<Swift.UInt32>>
    public typealias Int64 = Primitive<NumericProjection<Swift.Int64>>
    public typealias UInt64 = Primitive<NumericProjection<Swift.UInt64>>
    public typealias Float = Primitive<NumericProjection<Swift.Float>>
    public typealias Double = Primitive<NumericProjection<Swift.Double>>
    public typealias Char = Primitive<COM.WideCharProjection>
    public typealias String = Primitive<HStringProjection>
    public typealias Guid = Primitive<COM.GUIDProjection>

    public enum Primitive<Projection: ABIProjection>: ABIProjection {
        public typealias SwiftValue = Projection.SwiftValue?
        public typealias ABIValue = UnsafeMutablePointer<WindowsRuntime_ABI.SWRT_IReference>?

        public static var abiDefaultValue: ABIValue { nil }

        public static var interfaceID: COMInterfaceID {
            switch Projection.self {
                case is BoolProjection.Type: PropertyValueStatics.IReferenceIDs.bool
                case is NumericProjection<Swift.UInt8>.Type: PropertyValueStatics.IReferenceIDs.uint8
                case is NumericProjection<Swift.Int16>.Type: PropertyValueStatics.IReferenceIDs.int16
                case is NumericProjection<Swift.UInt16>.Type: PropertyValueStatics.IReferenceIDs.uint16
                case is NumericProjection<Swift.Int32>.Type: PropertyValueStatics.IReferenceIDs.int32
                case is NumericProjection<Swift.UInt32>.Type: PropertyValueStatics.IReferenceIDs.uint32
                case is NumericProjection<Swift.Int64>.Type: PropertyValueStatics.IReferenceIDs.int64
                case is NumericProjection<Swift.UInt64>.Type: PropertyValueStatics.IReferenceIDs.uint64
                case is NumericProjection<Swift.Float>.Type: PropertyValueStatics.IReferenceIDs.single
                case is NumericProjection<Swift.Double>.Type: PropertyValueStatics.IReferenceIDs.double
                case is COM.WideCharProjection.Type: PropertyValueStatics.IReferenceIDs.char16
                case is HStringProjection.Type: PropertyValueStatics.IReferenceIDs.string
                case is COM.GUIDProjection.Type: PropertyValueStatics.IReferenceIDs.guid
                default: fatalError("Invalid generic parameter: IReferenceProjection.Primitive<\(Projection.self)>")
            }
        }

        public static func toSwift(_ comPointer: ABIValue) -> SwiftValue {
            guard let comPointer else { return nil }
            var value: Projection.ABIValue = Projection.abiDefaultValue
            withUnsafeMutablePointer(to: &value) { valuePointer in
                try! WinRTError.throwIfFailed(comPointer.pointee.lpVtbl.pointee.get_Value(
                    comPointer, UnsafeMutableRawPointer(valuePointer)))
            }
            return Projection.toSwift(value)
        }

        private static func box(_ value: Projection.SwiftValue) throws -> COMReference<SWRT_IInspectable> {
            switch value {
                case let value as Swift.Bool: return try PropertyValueStatics.createBoolean(value)
                case let value as Swift.UInt8: return try PropertyValueStatics.createUInt8(value)
                case let value as Swift.Int16: return try PropertyValueStatics.createInt16(value)

                // UInt16 aka Unicode.UTF16.CodeUnit must be disambiguated from the projection type
                case let value as Swift.UInt16:
                    return try Projection.self == COM.WideCharProjection.self
                        ? PropertyValueStatics.createChar16(value)
                        : PropertyValueStatics.createUInt16(value)

                case let value as Swift.Int32: return try PropertyValueStatics.createInt32(value)
                case let value as Swift.UInt32: return try PropertyValueStatics.createUInt32(value)
                case let value as Swift.Int64: return try PropertyValueStatics.createInt64(value)
                case let value as Swift.UInt64: return try PropertyValueStatics.createUInt64(value)
                case let value as Swift.Float: return try PropertyValueStatics.createSingle(value)
                case let value as Swift.Double: return try PropertyValueStatics.createDouble(value)
                case let value as Swift.String: return try PropertyValueStatics.createString(value)
                case let value as Foundation.UUID: return try PropertyValueStatics.createGuid(value)
                default: throw HResult.Error.fail
            }
        }

        public static func toABI(_ value: SwiftValue) throws -> ABIValue {
            guard let value else { return nil }

            let inspectable = try box(value)
            return try inspectable.interop.queryInterface(Self.interfaceID)
                .reinterpret(to: WindowsRuntime_ABI.SWRT_IReference.self)
                .detach()
        }

        public static func release(_ value: inout ABIValue) {
            guard let comPointer = value else { return }
            COMInterop(comPointer).release()
            value = nil
        }
    }
}
