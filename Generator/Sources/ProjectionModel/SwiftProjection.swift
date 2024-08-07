import Collections
import DotNetMetadata
import DotNetXMLDocs

public class SwiftProjection {
    internal struct AssemblyEntry {
        var module: Module
        var documentation: AssemblyDocumentation?
    }

    public private(set) var modulesByName = OrderedDictionary<String, Module>()
    internal var assembliesToModules = [Assembly: AssemblyEntry]()
    public var referenceReturnNullability: ReferenceNullability { .explicit } 

    public init() {}

    public func addModule(name: String, flattenNamespaces: Bool = false) -> Module {
        precondition(modulesByName[name] == nil)
        let module = Module(projection: self, name: name, flattenNamespaces: flattenNamespaces)
        modulesByName[name] = module
        modulesByName.sort { $0.key < $1.key }
        return module
    }

    public func getModule(_ assembly: Assembly) -> Module? {
        assembliesToModules[assembly]?.module
    }
}