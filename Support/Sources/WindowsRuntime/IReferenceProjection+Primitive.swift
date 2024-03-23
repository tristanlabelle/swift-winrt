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
                case is BoolProjection.Type: PrimitiveBoxing.IReferenceIDs.bool
                case is NumericProjection<Swift.UInt8>.Type: PrimitiveBoxing.IReferenceIDs.uint8
                case is NumericProjection<Swift.Int16>.Type: PrimitiveBoxing.IReferenceIDs.int16
                case is NumericProjection<Swift.UInt16>.Type: PrimitiveBoxing.IReferenceIDs.uint16
                case is NumericProjection<Swift.Int32>.Type: PrimitiveBoxing.IReferenceIDs.int32
                case is NumericProjection<Swift.UInt32>.Type: PrimitiveBoxing.IReferenceIDs.uint32
                case is NumericProjection<Swift.Int64>.Type: PrimitiveBoxing.IReferenceIDs.int64
                case is NumericProjection<Swift.UInt64>.Type: PrimitiveBoxing.IReferenceIDs.uint64
                case is NumericProjection<Swift.Float>.Type: PrimitiveBoxing.IReferenceIDs.single
                case is NumericProjection<Swift.Double>.Type: PrimitiveBoxing.IReferenceIDs.double
                case is COM.WideCharProjection.Type: PrimitiveBoxing.IReferenceIDs.char16
                case is HStringProjection.Type: PrimitiveBoxing.IReferenceIDs.string
                case is COM.GUIDProjection.Type: PrimitiveBoxing.IReferenceIDs.guid
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
                case let value as Swift.Bool: return try PrimitiveBoxing.boolean(value)
                case let value as Swift.UInt8: return try PrimitiveBoxing.uint8(value)
                case let value as Swift.Int16: return try PrimitiveBoxing.int16(value)

                // UInt16 aka Unicode.UTF16.CodeUnit must be disambiguated from the projection type
                case let value as Swift.UInt16:
                    return try Projection.self == COM.WideCharProjection.self
                        ? PrimitiveBoxing.char16(value)
                        : PrimitiveBoxing.uint16(value)

                case let value as Swift.Int32: return try PrimitiveBoxing.int32(value)
                case let value as Swift.UInt32: return try PrimitiveBoxing.uint32(value)
                case let value as Swift.Int64: return try PrimitiveBoxing.int64(value)
                case let value as Swift.UInt64: return try PrimitiveBoxing.uint64(value)
                case let value as Swift.Float: return try PrimitiveBoxing.single(value)
                case let value as Swift.Double: return try PrimitiveBoxing.double(value)
                case let value as Swift.String: return try PrimitiveBoxing.string(value)
                case let value as Foundation.UUID: return try PrimitiveBoxing.guid(value)
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
            IUnknownPointer.release(comPointer)
            value = nil
        }
    }
}
