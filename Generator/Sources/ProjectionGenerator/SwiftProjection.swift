import DotNetMetadata
import DotNetXMLDocs

public class SwiftProjection {
    internal struct AssemblyEntry {
        var module: Module
        var documentation: AssemblyDocumentation?
    }

    public private(set) var modulesByShortName = [String: Module]()
    internal var assembliesToModules = [Assembly: AssemblyEntry]()
    public let abiModuleName: String
    public var referenceReturnNullability: ReferenceNullability { .explicit } 

    public init(abiModuleName: String) {
        self.abiModuleName = abiModuleName
    }

    public func addModule(shortName: String) -> Module {
        let module = Module(projection: self, shortName: shortName)
        modulesByShortName[shortName] = module
        return module
    }

    public func getModule(_ assembly: Assembly) -> Module? {
        assembliesToModules[assembly]?.module
    }

    internal func getDocumentation(_ assembly: Assembly) -> AssemblyDocumentation? {
        assembliesToModules[assembly]?.documentation
    }

    internal func getDocumentation(_ typeDefinition: TypeDefinition) -> MemberDocumentation? {
        guard let documentationFile = getDocumentation(typeDefinition.assembly) else { return nil }
        return documentationFile.members[.type(fullName: typeDefinition.fullName)]
    }

    internal func getDocumentation(_ member: Member) throws -> MemberDocumentation? {
        guard let documentationFile = getDocumentation(member.definingType.assembly) else { return nil }

        let memberKey: MemberDocumentationKey
        switch member {
            case let field as Field:
                memberKey = .field(declaringType: field.definingType.fullName, name: field.name)
            case let event as Event:
                memberKey = .event(declaringType: event.definingType.fullName, name: event.name)
            case let property as Property:
                guard try (property.getter?.arity ?? 0) == 0 else { return nil }
                memberKey = .event(declaringType: property.definingType.fullName, name: property.name)
            default:
                return nil
        }

        return documentationFile.members[memberKey]
    }
}