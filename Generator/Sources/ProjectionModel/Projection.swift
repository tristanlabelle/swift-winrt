import Collections
import DotNetMetadata
import DotNetXMLDocs

/// Describes how to project a collection of Windows metadata assemblies into Swift modules.
public class Projection {
    internal struct AssemblyEntry {
        var module: Module
        var documentation: AssemblyDocumentation?
    }

    public private(set) var modulesByName = OrderedDictionary<String, Module>()
    internal var assembliesToModules = [Assembly: AssemblyEntry]()
    public let deprecations: Bool

    public init(deprecations: Bool = true) {
        self.deprecations = deprecations
    }

    public func addModule(name: String) -> Module {
        precondition(modulesByName[name] == nil)
        let module = Module(projection: self, name: name)
        modulesByName[name] = module
        modulesByName.sort { $0.key < $1.key }
        return module
    }

    public func getModule(_ assembly: Assembly) -> Module? {
        assembliesToModules[assembly]?.module
    }

    internal func addAssembly(_ assembly: Assembly, module: Module, documentation: AssemblyDocumentation? = nil) {
        assembliesToModules[assembly] = AssemblyEntry(module: module, documentation: documentation)
    }
}