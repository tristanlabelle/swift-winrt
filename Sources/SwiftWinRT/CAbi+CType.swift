import DotNetMD

extension CAbi {
    struct CType: ExpressibleByStringLiteral {
        public static let hresult = CType(name: "HRESULT")

        public static func pointer(to name: String) -> CType {
            .init(name: name, pointerIndirections: 1)
        }

        var name: String
        var pointerIndirections: Int = 0

        init(stringLiteral name: String) {
            self.name = name
        }

        init(name: String, pointerIndirections: Int = 0) {
            self.name = name
            self.pointerIndirections = pointerIndirections
        }

        public var pointerIndirected: CType { .init(name: name, pointerIndirections: pointerIndirections + 1) }
    }

    public static func toCType(_ type: TypeNode) -> CType {
        if case let .bound(type) = type {
            // TODO: Handle special system types

            return CType(
                name: mangleName(type: type),
                pointerIndirections: type.definition.isReferenceType ? 1 : 0)
        }
        else {
            fatalError("Not implemented")
        }
    }
}