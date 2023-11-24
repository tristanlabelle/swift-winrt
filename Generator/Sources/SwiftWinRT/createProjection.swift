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

    let projectionConfig: ProjectionConfig
    if let configFilePath = generateCommand.config {
        let jsonData = try Data(contentsOf: URL(fileURLWithPath: configFilePath))
        projectionConfig = try JSONDecoder().decode(ProjectionConfig.self, from: jsonData)
    }
    else {
        projectionConfig = ProjectionConfig()
    }

    let projection = SwiftProjection(abiModuleName: projectionConfig.abiModule)

    // Preload assemblies and create modules
    for reference in allReferences {
        print("Loading assembly \(reference)...")
        let (assembly, assemblyDocumentation) = try loadAssemblyAndDocumentation(path: reference, into: assemblyLoadContext)
        let (moduleName, moduleConfig) = projectionConfig.getModule(assemblyName: assembly.name)
        let module = projection.modulesByName[moduleName] 
            ?? projection.addModule(name: moduleName, flattenNamespaces: moduleConfig.flattenNamespaces)
        module.addAssembly(assembly, documentation: assemblyDocumentation)
    }

    // Gather types from assemblies
    for assembly in assemblyLoadContext.loadedAssembliesByName.values {
        guard let module = projection.getModule(assembly) else { continue }

        print("Gathering types from \(assembly.name)...")
        var typeDiscoverer = ModuleTypeDiscoverer(assemblyFilter: { $0 === assembly }, publicMembersOnly: true)

        let (_, moduleConfig) = projectionConfig.getModule(assemblyName: assembly.name)
        let typeFilter = FilterSet(moduleConfig.types.map { $0.map { Filter(pattern: $0) } })

        for typeDefinition in assembly.definedTypes {
            guard typeDefinition.isPublic else { continue }
            guard typeDefinition.namespace != "Windows.Foundation.Metadata" else { continue }
            guard try !typeDefinition.hasAttribute(AttributeUsageAttribute.self) else { continue }
            guard try !typeDefinition.hasAttribute(ApiContractAttribute.self) else { continue }
            guard typeFilter.matches(typeDefinition.fullName) else { continue }
            try typeDiscoverer.add(typeDefinition)
        }

        for typeDefinition in typeDiscoverer.definitions { module.addTypeDefinition(typeDefinition) }
        for closedGenericType in typeDiscoverer.closedGenericTypes { module.addClosedGenericType(closedGenericType) }
    }

    // Establish references between modules
    for assembly in assemblyLoadContext.loadedAssembliesByName.values {
        guard !(assembly is Mscorlib) else { continue }

        if let sourceModule = projection.getModule(assembly) {
            for reference in assembly.references {
                if let targetModule = projection.getModule(try reference.resolve()) {
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
