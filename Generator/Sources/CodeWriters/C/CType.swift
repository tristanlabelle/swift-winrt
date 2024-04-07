public enum CTypeSpecifier {
    case reference(kind: CTypeDeclKind? = nil, name: String)
    indirect case pointer(to: CType, nullability: CNullability? = nil)
    indirect case functionPointer(return: CType, callingConvention: CCallingConvention? = nil, params: [CParamDecl] = [])
}

public enum CNullability {
    case nonnull
    case nullable
    case unspecified
}

public struct CType {
    public var specifier: CTypeSpecifier
    public var const: Bool = false
    public var volatile: Bool = false

    public init(_ specifier: CTypeSpecifier, const: Bool = false, volatile: Bool = false) {
        self.specifier = specifier
        self.const = const
        self.volatile = volatile
    }
}

extension CType {
    public static func reference(kind: CTypeDeclKind? = nil, name: String, const: Bool = false, volatile: Bool = false) -> Self {
        .init(.reference(kind: kind, name: name), const: const, volatile: volatile)
    }

    public static func pointer(to pointee: CType, const: Bool = false, volatile: Bool = false, nullability: CNullability? = nil) -> Self {
        .init(.pointer(to: pointee, nullability: nullability), const: const, volatile: volatile)
    }

    public static let void: Self = .reference(name: "void")

    public func makePointer(const: Bool = false, volatile: Bool = false, nullability: CNullability? = nil) -> Self {
        .init(.pointer(to: self, nullability: nullability), const: const, volatile: volatile)
    }
}