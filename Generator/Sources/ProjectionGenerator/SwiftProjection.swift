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
}