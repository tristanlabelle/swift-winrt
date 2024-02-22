import CodeWriters

/// Specifies how to express the nullability of WinRT reference types in Swift
public enum ReferenceNullability: Hashable {
    /// Specifies to use explicitly unwrapped optionals
    case explicit
    /// Specifies to use implicitly unwrapped optionals
    case implicit
    /// Specifies to not represent null values at all.
    /// Code might have to fail fast or throw errors when null values are encountered.
    case none
}

extension ReferenceNullability {
    public func disallowImplicit() -> ReferenceNullability {
        switch self {
            case .implicit:.explicit
            default: self
        }
    }

    public func applyTo(type: SwiftType) -> SwiftType {
        switch self {
            case .explicit: return .optional(wrapped: type, implicitUnwrap: false)
            case .implicit: return .optional(wrapped: type, implicitUnwrap: true)
            case .none: return type
        }
    }
}