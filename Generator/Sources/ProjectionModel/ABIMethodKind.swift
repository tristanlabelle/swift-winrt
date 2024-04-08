import DotNetMetadata
import WindowsMetadata

public enum ABIMethodKind: Equatable {
    case normal
    case activationFactory
    case composableFactory

    public static func forInterfaceMethods(definition: InterfaceDefinition) throws -> ABIMethodKind {
        guard let classDefinition = try definition.findAttribute(ExclusiveToAttribute.self)?.target else {
            return .normal
        }

        for activatableAttribute in try classDefinition.getAttributes(ActivatableAttribute.self) {
            if activatableAttribute.factory == definition {
                return .activationFactory
            }
        }

        for composableAttribute in try classDefinition.getAttributes(ComposableAttribute.self) {
            if composableAttribute.factory == definition {
                return .composableFactory
            }
        }

        return .normal
    }

    public static func forABITypeMethods(definition: TypeDefinition) throws -> ABIMethodKind {
        guard let interfaceDefinition = definition as? InterfaceDefinition else {
            return .normal
        }
        return try forInterfaceMethods(definition: interfaceDefinition)
    }
}