public enum CTypeDeclKind: Hashable {
    case `struct`
    case `enum`
    case union
}

extension CTypeDeclKind {
    public var keyword: String {
        switch self {
            case .struct: return "struct"
            case .enum: return "enum"
            case .union: return "union"
        }
    }
}