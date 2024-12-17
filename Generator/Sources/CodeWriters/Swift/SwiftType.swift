// Loosely based on https://docs.swift.org/swift-book/documentation/the-swift-programming-language/types
// However that grammar has a bug: it cannot represent "[Int].Element"
public enum SwiftType {
    // Self
    case `self`
    // Any
    case any

    // Foo<X, Y>
    case named(SwiftIdentifier, genericArgs: [SwiftType] = [])

    // X.Foo<Y, Z>
    indirect case member(of: SwiftType, SwiftIdentifier, genericArgs: [SwiftType] = [])

    // some X
    indirect case opaque(protocol: SwiftType)
    // any X
    indirect case existential(protocol: SwiftType)

    // X?
    indirect case `optional`(wrapped: SwiftType, implicitUnwrap: Bool = false)
    // (X, Y)
    indirect case tuple(elements: [SwiftType])
    // [X]
    indirect case array(element: SwiftType)
    // [X: Y]
    indirect case dictionary(key: SwiftType, value: SwiftType)
    // (X, Y) throws -> Z
    indirect case function(params: [SwiftType], throws: Bool = false, returnType: SwiftType)
}

extension SwiftType {
    public static func named(_ name: String, genericArgs: [SwiftType] = []) -> Self {
        .named(SwiftIdentifier(name), genericArgs: genericArgs)
    }

    public func metatype() -> Self { .member(of: self, "Type") }

    public func member(_ name: String, genericArgs: [SwiftType] = []) -> Self {
        member(SwiftIdentifier(name), genericArgs: genericArgs)
    }

    public func member(_ name: SwiftIdentifier, genericArgs: [SwiftType] = []) -> Self {
        .member(of: self, name, genericArgs: genericArgs)
    }

    public func opaque() -> Self { .opaque(protocol: self) }
    public func existential() -> Self { .existential(protocol: self) }

    public func optional(implicitUnwrap: Bool = false) -> Self {
        .optional(wrapped: self, implicitUnwrap: implicitUnwrap)
    }

    public func unwrapOptional() -> SwiftType {
        switch self {
            case let .optional(wrapped, _): return wrapped
            default: return self
        }
    }
}

extension SwiftType {
    private static let swiftModule: Self = .named("Swift")

    public static func swift(_ identifier: SwiftIdentifier, genericArgs: [SwiftType] = []) -> Self {
        swiftModule.member(identifier, genericArgs: genericArgs)
    }

    public static func swift(_ identifier: String, genericArgs: [SwiftType] = []) -> Self {
        swiftModule.member(SwiftIdentifier(identifier), genericArgs: genericArgs)
    }

    public static let void: Self = swift("Void")
    public static let anyObject: Self = swift("AnyObject")
    public static let never: Self = swift("Never")
    public static let bool: Self = swift("Bool")
    public static let float: Self = swift("Float")
    public static let double: Self = swift("Double")
    public static let string: Self = swift("String")
    public static let int: Self = swift("Int")
    public static let uint: Self = swift("UInt")

    public static func int(bits: Int, signed: Bool = true) -> Self {
        switch (bits, signed) {
            case (8, true): return swift("Int8")
            case (8, false): return swift("UInt8")
            case (16, true): return swift("Int16")
            case (16, false): return swift("UInt16")
            case (32, true): return swift("Int32")
            case (32, false): return swift("UInt32")
            case (64, true): return swift("Int64")
            case (64, false): return swift("UInt64")
            default: preconditionFailure("bits should be one of 8, 16, 32 or 64")
        }
    }

    public static func uint(bits: Int) -> Self { int(bits: bits, signed: false) }

    public static func unsafePointer(pointee: SwiftType) -> SwiftType {
        swift("UnsafePointer", genericArgs: [pointee])
    }

    public static func unsafeMutablePointer(pointee: SwiftType) -> SwiftType {
        swift("UnsafeMutablePointer", genericArgs: [pointee])
    }
}
