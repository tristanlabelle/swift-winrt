import CodeWriters
import DotNetMetadata

internal struct ParamProjection {
    public enum PassBy: Equatable {
        case value
        case reference(in: Bool, out: Bool, optional: Bool)
        case `return`
    }

    public let name: String
    public let typeProjection: TypeProjection
    public let passBy: PassBy

    public var projectionType: SwiftType { typeProjection.projectionType }
    public var abiProjectionName: String { name + "_abi" }
    public var swiftProjectionName: String { name + "_swift" }
    public var isArray: Bool { typeProjection.kind == .array }
    public var arrayLengthName: String {
        precondition(isArray)
        return name + "Length"
    }
}

extension ParamProjection.PassBy {
    public var isInput: Bool {
        switch self {
            case .value, .reference(in: true, out: _, optional: _): return true
            default: return false
        }
    }

    public var isReference: Bool {
        switch self {
            case .reference: return true
            default: return false
        }
    }

    public var isOutput: Bool {
        switch self {
            case .reference(in: _, out: true, optional: _), .return: return true
            default: return false
        }
    }
}