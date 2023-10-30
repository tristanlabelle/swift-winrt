import DotNetMetadata
import DotNetXMLDocs

public class SwiftProjection {
    internal struct AssemblyEntry {
        var module: Module
        var documentation: DocumentationFile?
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

    internal func getDocumentation(_ assembly: Assembly) -> DocumentationFile? {
        assembliesToModules[assembly]?.documentation
    }

    internal func getDocumentation(_ typeDefinition: TypeDefinition) -> DotNetXMLDocs.MemberEntry? {
        guard let documentationFile = getDocumentation(typeDefinition.assembly) else { return nil }
        return documentationFile.members[.type(fullName: typeDefinition.fullName)]
    }

    internal func getDocumentation(_ member: Member) throws -> DotNetXMLDocs.MemberEntry? {
        guard let documentationFile = getDocumentation(member.definingType.assembly) else { return nil }

        let memberKey: DotNetXMLDocs.MemberKey
        switch member {
            case let field as Field:
                memberKey = .field(typeFullName: field.definingType.fullName, name: field.name)
            case let event as Event:
                memberKey = .event(typeFullName: event.definingType.fullName, name: event.name)
            case let property as Property:
                guard try (property.getter?.arity ?? 0) == 0 else { return nil }
                memberKey = .event(typeFullName: property.definingType.fullName, name: property.name)
            default:
                return nil
        }

        return documentationFile.members[memberKey]
    }
}