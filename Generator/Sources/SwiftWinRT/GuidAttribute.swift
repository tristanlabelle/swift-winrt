import DotNetMetadata

struct GuidAttribute {
    public var a: UInt32
    public var b: UInt16
    public var c: UInt16
    public var d: UInt8
    public var e: UInt8
    public var f: UInt8
    public var g: UInt8
    public var h: UInt8
    public var i: UInt8
    public var j: UInt8
    public var k: UInt8

    public static func get(from interface: InterfaceDefinition) throws -> GuidAttribute {
        // // [Windows.Foundation.Metadata.Guid(1516535814u, 33850, 19881, 134, 91, 157, 38, 229, 223, 173, 123)]
        guard let attribute = try interface.attributes.first(where: {
            try $0.type.fullName == "Windows.Foundation.Metadata.GuidAttribute"
        }) else { throw ProjectionError.invalidGuidAttribute }

        let arguments = try attribute.arguments
        guard arguments.count == 11 else { throw ProjectionError.invalidGuidAttribute }

        func toConstant(_ value: Attribute.Value) throws -> Constant {
            switch value {
                case let .constant(constant): return constant
                default: throw ProjectionError.invalidGuidAttribute
            }
        }

        guard case .uint32(let a) = try toConstant(arguments[0]) else { throw ProjectionError.invalidGuidAttribute }
        guard case .uint16(let b) = try toConstant(arguments[1]) else { throw ProjectionError.invalidGuidAttribute }
        guard case .uint16(let c) = try toConstant(arguments[2]) else { throw ProjectionError.invalidGuidAttribute }
        let rest = try arguments[3...].map {
            guard case .uint8(let value) = try toConstant($0) else { throw ProjectionError.invalidGuidAttribute }
            return value
        }

        return GuidAttribute(
            a: a, b: b, c: c,
            d: rest[0], e: rest[1], f: rest[2], g: rest[3], h: rest[4], i: rest[5], j: rest[6], k: rest[7])
    }
}