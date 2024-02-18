import CodeWriters
import DotNetMetadata

public struct ParamProjection {
    public enum PassBy: Equatable {
        case value
        case reference(in: Bool, out: Bool, optional: Bool)
        case `return`(nullAsError: Bool)
    }

    public let name: String
    public let typeProjection: TypeProjection
    public let passBy: PassBy

    public init(name: String, typeProjection: TypeProjection, passBy: PassBy) {
        self.name = name
        self.typeProjection = typeProjection
        self.passBy = passBy
    }

    public var projectionType: SwiftType { typeProjection.projectionType }
    public var abiProjectionName: String { name + "_abi" }
    public var swiftProjectionName: String { name + "_swift" }
    public var isArray: Bool { typeProjection.kind == .array }
    public var arrayLengthName: String {
        precondition(isArray)
        return name + "Length"
    }

    public func toSwiftParam(label: String = "_") -> SwiftParam {
        SwiftParam(label: label, name: name, `inout`: passBy.isOutput, type: typeProjection.swiftType)
    }

    public func toSwiftReturnType() -> SwiftType {
        if case .return(nullAsError: true) = passBy { return typeProjection.swiftType.unwrapOptional() }
        return typeProjection.swiftType
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