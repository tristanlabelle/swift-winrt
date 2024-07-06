import DotNetMetadata
import DotNetXMLDocs
import Foundation
import ProjectionModel
import WindowsMetadata

internal func createProjection(generateCommand: GenerateCommand, projectionConfig: ProjectionConfig, assemblyLoadContext: AssemblyLoadContext) throws -> SwiftProjection {
    var allReferences = Set(generateCommand.references)
    if let sdk = generateCommand.windowsSdkVersion {
        allReferences.insert("C:\\Program Files (x86)\\Windows Kits\\10\\UnionMetadata\\\(sdk)\\Windows.winmd")
    }

    let projection = SwiftProjection()

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
    var typeDiscoverer = WinRTTypeDiscoverer()
    for assembly in assemblyLoadContext.loadedAssembliesByName.values {
        print("Gathering types from \(assembly.name)...")

        let (_, moduleConfig) = projectionConfig.getModule(assemblyName: assembly.name)
        let typeFilter = FilterSet(moduleConfig.types.map { $0.map { Filter(pattern: $0) } })

        for typeDefinition in assembly.typeDefinitions {
            guard try !typeDefinition.hasAttribute(WindowsMetadata.AttributeUsageAttribute.self) else { continue }
            guard try !typeDefinition.hasAttribute(ApiContractAttribute.self) else { continue }
            guard typeFilter.matches(typeDefinition.fullName) else { continue }
            try typeDiscoverer.add(typeDefinition)
        }
    }

    // Sort discovered types in their respective modules
    for (assembly, types) in typeDiscoverer.typesByAssembly {
        guard let module = projection.getModule(assembly) else { continue }

        for typeDefinition in types.definitions {
            module.addTypeDefinition(typeDefinition)
        }

        for genericInstantiation in types.genericInstantiations {
            module.addGenericInstantiation(genericInstantiation)
        }
    }

    // Establish references between modules
    for assembly in assemblyLoadContext.loadedAssembliesByName.values {
        guard assembly.name != "mscorlib" else { continue }

        if let sourceModule = projection.getModule(assembly) {
            for reference in assembly.references {
                if let targetModule = projection.getModule(try reference.resolve()), targetModule !== sourceModule {
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
