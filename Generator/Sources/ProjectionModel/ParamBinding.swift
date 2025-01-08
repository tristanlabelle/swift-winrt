import CodeWriters
import DotNetMetadata

/// Describes how a WinMD function parameter gets mapped to a Swift function parameter and vice-versa.
public struct ParamBinding {
    public enum PassBy: Equatable {
        case value
        case reference(in: Bool, out: Bool, optional: Bool)
        case `return`(nullAsError: Bool)
    }

    public let name: String
    public let typeBinding: TypeBinding
    public let passBy: PassBy

    public init(name: String, typeBinding: TypeBinding, passBy: PassBy) {
        self.name = name
        self.typeBinding = typeBinding
        self.passBy = passBy
    }

    public var bindingType: SwiftType { typeBinding.bindingType }

    public var swiftType: SwiftType {
        if case .return(nullAsError: true) = passBy { return typeBinding.swiftType.unwrapOptional() }
        return typeBinding.swiftType
    }

    public var abiBindingName: String { name + "_abi" }
    public var swiftBindingName: String { name + "_swift" }
    public var isArray: Bool { typeBinding.kind == .array }
    public var arrayLengthName: String {
        precondition(isArray)
        return name + "Length"
    }

    public func toSwiftParam(label: String = "_") -> SwiftParam {
        SwiftParam(label: label, name: name, `inout`: passBy.isOutput, type: typeBinding.swiftType)
    }
}

extension ParamBinding.PassBy {
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