import DotNetMetadata
import DotNetXMLDocs
import Foundation
import OrderedCollections
import ProjectionModel
import WindowsMetadata

internal func createProjection(commandLineArguments: CommandLineArguments, projectionConfig: ProjectionConfig, winMDLoadContext: WinMDLoadContext) throws -> Projection {
    var winMDFilePaths = OrderedSet(commandLineArguments.references)
    if let windowsSdkVersion = commandLineArguments.windowsSdkVersion {
        winMDFilePaths.formUnion(try getWindowsSdkWinMDPaths(sdkVersion: windowsSdkVersion))
    }

    let projection = Projection(
        deprecations: !commandLineArguments.noDeprecations)

    // Preload assemblies and create modules
    for filePath in winMDFilePaths.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
        print("Loading assembly \(filePath.lastPathComponent)...")

        let assembly = try winMDLoadContext.load(path: filePath)
        let assemblyDocumentation = commandLineArguments.noDocs ? nil
            : try tryLoadDocumentation(assemblyPath: filePath, locales: commandLineArguments.locales)
        let (moduleName, _) = projectionConfig.getModule(assemblyName: assembly.name)
        let module = projection.modulesByName[moduleName] ?? projection.addModule(name: moduleName)
        module.addAssembly(assembly, documentation: assemblyDocumentation)
    }

    // Gather types from assemblies
    var typeDiscoverer = WinRTTypeDiscoverer()
    for (assemblyName, assembly) in winMDLoadContext.loadedAssembliesByName.sorted(by: { $0.key < $1.key }) {
        guard assemblyName != "mscorlib" else { continue }

        print("Gathering types from \(assemblyName)...")

        let (_, moduleConfig) = projectionConfig.getModule(assemblyName: assembly.name)
        let typeFilter = FilterSet(moduleConfig.types.map { $0.map { Filter(pattern: $0) } })
        guard !typeFilter.matchesNothing else { continue }

        for typeDefinition in assembly.typeDefinitions {
            guard typeDefinition.isPublic else { continue } // WinRT types should be public, but avoid the dummy "<Module>" type
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

    func addReference(sourceModule: Module, targetAssembly: Assembly) {
        if let targetModule = projection.getModule(targetAssembly), targetModule !== sourceModule {
            sourceModule.addReference(targetModule)
        }
    }

    // Establish references between modules
    for assembly in winMDLoadContext.loadedAssembliesByName.values {
        guard assembly.name != "mscorlib" else { continue }

        if let sourceModule = projection.getModule(assembly) {
            for reference in assembly.references {
                if WinMDLoadContext.isUWPAssembly(name: reference.name) {
                    // UWP references are messy and not always resolvable.
                    if let targetAssembly = winMDLoadContext.findLoaded(name: reference.name) {
                        addReference(sourceModule: sourceModule, targetAssembly: targetAssembly)
                    }
                    else {
                        // Reference all modules that have loaded Windows.* assemblies.
                        // This handles a reference to "Windows" when we've loaded "Windows.Foundation.FoundationContract", or vice-versa.
                        for assembly in winMDLoadContext.loadedAssembliesByName.values {
                            if WinMDLoadContext.isUWPAssembly(name: assembly.name) {
                                addReference(sourceModule: sourceModule, targetAssembly: assembly)
                            }
                        }
                    }
                }
                else {
                    addReference(sourceModule: sourceModule, targetAssembly: try reference.resolve())
                }
            }
        }
    }

    return projection
}

fileprivate func getWindowsSdkWinMDPaths(sdkVersion: String) throws -> [String] {
    guard let sdkVersion = FourPartVersion(parsing: sdkVersion),
            let windowsKit = try WindowsKit.getInstalled().first(where: { $0.version == sdkVersion }) else {
        enum WindowsSDKError: Error {
            case notFound(version: String)
        }
        throw WindowsSDKError.notFound(version: sdkVersion)
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