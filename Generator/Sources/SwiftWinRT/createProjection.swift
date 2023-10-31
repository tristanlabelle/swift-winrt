import DotNetMetadata
import DotNetXMLDocs
import Foundation
import ProjectionGenerator
import WindowsMetadata

internal func createProjection(generateCommand: GenerateCommand, assemblyLoadContext: AssemblyLoadContext) throws -> SwiftProjection {
    var allReferences = Set(generateCommand.references)
    if let sdk = generateCommand.sdk {
        allReferences.insert("C:\\Program Files (x86)\\Windows Kits\\10\\UnionMetadata\\\(sdk)\\Windows.winmd")
    }

    let moduleMap: ModuleMapFile?
    if let moduleMapPath = generateCommand.moduleMap {
        moduleMap = try JSONDecoder().decode(ModuleMapFile.self, from: Data(contentsOf: URL(fileURLWithPath: moduleMapPath)))
    }
    else {
        moduleMap = nil
    }

    let swiftProjection = SwiftProjection(abiModuleName: generateCommand.abiModuleName)

    // Create modules and gather types
    for reference in allReferences {
        let (assembly, assemblyDocumentation) = try loadAssemblyAndDocumentation(path: reference, into: context)
        let (moduleName, moduleMapping) = getModule(assemblyName: assembly.name, moduleMapFile: moduleMap)
        let module = swiftProjection.modulesByShortName[moduleName] ?? swiftProjection.addModule(shortName: moduleName)
        module.addAssembly(assembly, documentation: assemblyDocumentation)

        print("Gathering types from \(assembly.name)...")
        var typeDiscoverer = ModuleTypeDiscoverer(assemblyFilter: { $0 === assembly }, publicMembersOnly: true)

        try typeDiscoverer.add(assembly.findDefinedType(fullName: "Windows.Foundation.Collections.StringMap")!)

        for typeDefinition in assembly.definedTypes {
            guard typeDefinition.isPublic else { continue }
            guard typeDefinition.namespace != "Windows.Foundation.Metadata" else { continue }
            guard try !typeDefinition.hasAttribute(AttributeUsageAttribute.self) else { continue }
            guard try !typeDefinition.hasAttribute(ApiContractAttribute.self) else { continue }
            guard isIncluded(fullName: typeDefinition.fullName, filters: moduleMapping?.includeFilters) else { continue }
            try typeDiscoverer.add(typeDefinition)
        }

        for typeDefinition in typeDiscoverer.definitions { module.addTypeDefinition(typeDefinition) }
        for closedGenericType in typeDiscoverer.closedGenericTypes { module.addClosedGenericType(closedGenericType) }
    }

    // Establish references between modules
    for assembly in context.loadedAssembliesByName.values {
        guard !(assembly is Mscorlib) else { continue }

        if let sourceModule = swiftProjection.getModule(assembly) {
            for reference in assembly.references {
                if let targetModule = swiftProjection.getModule(try reference.resolve()) {
                    sourceModule.addReference(targetModule)
                }
            }
        }
    }

    return projection
}

fileprivate func loadAssemblyAndDocumentation(
        path: String, languageCode: String? = "en",
        into context: AssemblyLoadContext) throws -> (assembly: Assembly, docs: AssemblyDocumentation?) {
    let assembly = try context.load(path: path)
    var docs: AssemblyDocumentation? = nil
    if let lastPathSeparator = path.lastIndex(where: { $0 == "\\" || $0 == "/" }) {
        let assemblyDirectoryPath = String(path[..<lastPathSeparator])
        let assemblyFileName = String(path[path.index(after: lastPathSeparator)...])
        if let extensionDot = assemblyFileName.lastIndex(of: ".") {
            let assemblyFileNameWithoutExtension = String(assemblyFileName[..<extensionDot])
            let sideBySideDocsPath = "\(assemblyDirectoryPath)\\\(assemblyFileNameWithoutExtension).xml"
            if FileManager.default.fileExists(atPath: sideBySideDocsPath) {
                docs = try AssemblyDocumentation(readingFileAtPath: sideBySideDocsPath)
            }
            else if let languageCode {
                let languageNestedDocsPath = "\(assemblyDirectoryPath)\\\(languageCode)\\\(assemblyFileNameWithoutExtension).xml"
                if FileManager.default.fileExists(atPath: languageNestedDocsPath) {
                    docs = try AssemblyDocumentation(readingFileAtPath: languageNestedDocsPath)
                }
            }
        }
    }
    return (assembly, docs)
}

fileprivate func getModule(assemblyName: String, moduleMapFile: ModuleMapFile?) -> (name: String, mapping: ModuleMapFile.Module?) {
    if let moduleMapFile {
        for (moduleName, module) in moduleMapFile.modules {
            if module.assemblies.contains(assemblyName) {
                return (moduleName, module)
            }
        }
    }

    return (assemblyName, nil)
}

fileprivate func isIncluded(fullName: String, filters: [String]?) -> Bool {
    guard let filters else { return true }

    for filter in filters {
        if filter.last == "*" {
            if fullName.starts(with: filter.dropLast()) {
                return true
            }
        }
        else if fullName == filter {
            return true
        }
    }

    return false
}