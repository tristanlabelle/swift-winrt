import DotNetMetadata
import DotNetXMLDocs
import Foundation
import OrderedCollections
import ProjectionModel
import WindowsMetadata

internal func createProjection(commandLineArguments: CommandLineArguments, projectionConfig: ProjectionConfig, assemblyLoadContext: AssemblyLoadContext) throws -> SwiftProjection {
    var winMDFilePaths = OrderedSet(commandLineArguments.references)
    if let windowsSdkVersion = commandLineArguments.windowsSdkVersion {
        winMDFilePaths.formUnion(try getWindowsSdkWinMDPaths(sdkVersion: windowsSdkVersion))
    }

    let projection = SwiftProjection()

    // Preload assemblies and create modules
    for filePath in winMDFilePaths.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
        print("Loading assembly \(filePath.lastPathComponent)...")

        let assembly = try assemblyLoadContext.load(path: filePath)
        let assemblyDocumentation = commandLineArguments.noDocs ? nil
            : try tryLoadDocumentation(assemblyPath: filePath, locales: commandLineArguments.locales)
        let (moduleName, moduleConfig) = projectionConfig.getModule(assemblyName: assembly.name)
        let module = projection.modulesByName[moduleName] 
            ?? projection.addModule(name: moduleName, flattenNamespaces: moduleConfig.flattenNamespaces)
        module.addAssembly(assembly, documentation: assemblyDocumentation)
    }

    // Gather types from assemblies
    var typeDiscoverer = WinRTTypeDiscoverer()
    for (assemblyName, assembly) in assemblyLoadContext.loadedAssembliesByName.sorted(by: { $0.key < $1.key }) {
        guard assemblyName != "mscorlib" else { continue }

        print("Gathering types from \(assemblyName)...")

        let (_, moduleConfig) = projectionConfig.getModule(assemblyName: assembly.name)
        let typeFilter = FilterSet(moduleConfig.types.map { $0.map { Filter(pattern: $0) } })
        guard !typeFilter.matchesNothing else { continue }

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

fileprivate func getWindowsSdkWinMDPaths(sdkVersion: String) throws -> [String] {
    let sdkVersion = try FourPartVersion(parsing: sdkVersion)
    guard let windowsKit = try WindowsKit.getInstalled().first(where: { $0.version == sdkVersion }) else {
        enum WindowsSDKError: Error {
            case notFound(version: String)
        }
        throw WindowsSDKError.notFound(version: sdkVersion.description)
    }

    let applicationPlatform = try windowsKit.readApplicationPlatform()
    var apiContracts = applicationPlatform.apiContracts

    if let desktopExtension = windowsKit.extensions.first(where: { $0.name == "WindowsDesktop" }) {
        for extensionApiContract in try desktopExtension.readManifest().apiContracts {
            apiContracts[extensionApiContract.key] = extensionApiContract.value
        }
    }

    return apiContracts.map {
        windowsKit.getAPIContractPath(name: $0.key, version: $0.value)
    }
}

fileprivate func tryLoadDocumentation(assemblyPath: String, locales: [String]) throws -> AssemblyDocumentation? {
    let lastPathSeparator = assemblyPath.lastIndex(where: { $0 == "\\" || $0 == "/" })

    let assemblyDirectoryPath = lastPathSeparator == nil ? "." : String(assemblyPath[..<lastPathSeparator!])
    let assemblyFileName = lastPathSeparator == nil ? assemblyPath : String(assemblyPath[assemblyPath.index(after: lastPathSeparator!)...])

    guard let extensionDot = assemblyFileName.lastIndex(of: ".") else { return nil }
    let assemblyFileNameWithoutExtension = String(assemblyFileName[..<extensionDot])

    for locale in locales {
        let languageNestedDocsPath = "\(assemblyDirectoryPath)\\\(locale)\\\(assemblyFileNameWithoutExtension).xml"
        if FileManager.default.fileExists(atPath: languageNestedDocsPath) {
            return try AssemblyDocumentation(readingFileAtPath: languageNestedDocsPath)
        }
    }

    let sideBySideDocsPath = "\(assemblyDirectoryPath)\\\(assemblyFileNameWithoutExtension).xml"
    if FileManager.default.fileExists(atPath: sideBySideDocsPath) {
        return try AssemblyDocumentation(readingFileAtPath: sideBySideDocsPath)
    }

    return nil
}