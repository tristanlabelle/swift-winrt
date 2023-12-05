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
    public let abiModuleName: String
    public var referenceReturnNullability: ReferenceNullability { .explicit } 

    public init(abiModuleName: String) {
        self.abiModuleName = abiModuleName
    }

    public func addModule(name: String, flattenNamespaces: Bool = false) -> Module {
        precondition(modulesByName[name] == nil)
        let module = Module(projection: self, name: name, flattenNamespaces: flattenNamespaces)
        modulesByName[name] = module
        return module
    }

    public func getModule(_ assembly: Assembly) -> Module? {
        assembliesToModules[assembly]?.module
    }
}