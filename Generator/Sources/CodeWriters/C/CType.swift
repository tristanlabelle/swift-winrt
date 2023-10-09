public struct CType: ExpressibleByStringLiteral {
    public static let hresult = CType(name: "HRESULT")
    public static let voidPointer = CType(name: "void", pointerIndirections: 1)

    public static func pointer(to name: String) -> CType {
        .init(name: name, pointerIndirections: 1)
    }

    public var name: String
    public var pointerIndirections: Int = 0

    public init(stringLiteral name: String) {
        self.name = name
    }

    public init(name: String, pointerIndirections: Int = 0) {
        self.name = name
        self.pointerIndirections = pointerIndirections
    }

    public func withPointerIndirection() -> CType {
        .init(name: name, pointerIndirections: pointerIndirections + 1)
    }
}
