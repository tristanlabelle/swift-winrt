import ArgumentParser
import ProjectionGenerator
import DotNetMetadata
import DotNetMetadataFormat
import DotNetXMLDocs
import Foundation
import WindowsMetadata

@main
struct EntryPoint: ParsableCommand {
    @Option(name: .customLong("reference"), help: "A path to a .winmd file with the APIs to project.")
    var references: [String] = []

    @Option(help: "A Windows SDK version with the APIs to project.")
    var sdk: String? = nil

    @Option(name: .customLong("module-map"), help: "A path to a module map json file to use.")
    var moduleMap: String? = nil

    @Option(name: .customLong("abi-module"), help: "The name of the C ABI module.")
    var abiModuleName: String = "CAbi"

    @Option(help: "A path to the output directory.")
    var out: String

    mutating func run() throws {
        var allReferences = Set(references)
        if let sdk {
            allReferences.insert("C:\\Program Files (x86)\\Windows Kits\\10\\UnionMetadata\\\(sdk)\\Windows.winmd")
        }

        let moduleMap: ModuleMapFile?
        if let moduleMapPath = self.moduleMap {
            moduleMap = try JSONDecoder().decode(ModuleMapFile.self, from: Data(contentsOf: URL(fileURLWithPath: moduleMapPath)))
        }
        else {
            moduleMap = nil
        }

        // Resolve the mscorlib dependency from the .NET Framework 4 machine installation
        struct AssemblyLoadError: Error {}
        let context = AssemblyLoadContext()

        guard let mscorlibPath = SystemAssemblies.DotNetFramework4.mscorlibPath else {
            throw AssemblyLoadError()
        }
        _ = try context.load(path: mscorlibPath)

        let swiftProjection = SwiftProjection(abiModuleName: abiModuleName)

        // Create modules and gather types
        for reference in allReferences {
            let (assembly, assemblyDocumentation) = try Self.loadAssemblyAndDocumentation(path: reference, into: context)
            let (moduleName, moduleMapping) = Self.getModule(assemblyName: assembly.name, moduleMapFile: moduleMap)
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
                guard Self.isIncluded(fullName: typeDefinition.fullName, filters: moduleMapping?.includeFilters) else { continue }
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

        for module in swiftProjection.modulesByShortName.values {
            let moduleRootPath = "\(out)\\\(module.shortName)"
            let assemblyModuleDirectoryPath = "\(moduleRootPath)\\Assembly"
            try FileManager.default.createDirectory(atPath: assemblyModuleDirectoryPath, withIntermediateDirectories: true)

            for (namespace, typeDefinitions) in module.typeDefinitionsByNamespace {
                let compactNamespace = namespace == "" ? "global" : SwiftProjection.toCompactNamespace(namespace)
                print("Writing \(module.shortName)/\(compactNamespace).swift...")

                let definitionsPath = "\(assemblyModuleDirectoryPath)\\\(compactNamespace).swift"
                let projectionsPath = "\(assemblyModuleDirectoryPath)\\\(compactNamespace)+Projections.swift"
                let namespaceModuleDirectoryPath = "\(moduleRootPath)\\Namespaces\\\(compactNamespace)"
                let namespaceAliasesPath = "\(namespaceModuleDirectoryPath)\\Aliases.swift"
                try FileManager.default.createDirectory(atPath: namespaceModuleDirectoryPath, withIntermediateDirectories: true)

                let definitionsWriter = SwiftAssemblyModuleFileWriter(path: definitionsPath, module: module, importAbiModule: false)
                let projectionsWriter = SwiftAssemblyModuleFileWriter(path: projectionsPath, module: module, importAbiModule: true)
                let aliasesWriter = SwiftNamespaceModuleFileWriter(path: namespaceAliasesPath, module: module)
                for typeDefinition in typeDefinitions.sorted(by: { $0.fullName < $1.fullName }) {
                    // Some types have special handling and should not have their projection code generated
                    guard typeDefinition.fullName != "Windows.Foundation.HResult" else { continue }
                    guard typeDefinition.fullName != "Windows.Foundation.EventRegistrationToken" else { continue }
                    if let structDefinition = typeDefinition as? StructDefinition {
                        guard try !structDefinition.hasAttribute(ApiContractAttribute.self) else { continue }
                    }

                    try definitionsWriter.writeTypeDefinition(typeDefinition)
                    try projectionsWriter.writeProjection(typeDefinition)
                    if typeDefinition.isPublic {
                        try aliasesWriter.writeAliases(typeDefinition)
                    }
                }
            }

            if !module.closedGenericTypesByDefinition.isEmpty {
                let genericsPath = "\(assemblyModuleDirectoryPath)\\_Generics.swift"
                let fileWriter = SwiftAssemblyModuleFileWriter(path: genericsPath, module: module, importAbiModule: true)
                let closedGenericTypesByDefinition = module.closedGenericTypesByDefinition
                    .sorted { $0.key.fullName < $1.key.fullName }
                for (typeDefinition, instanciations) in closedGenericTypesByDefinition {
                    if !module.hasTypeDefinition(typeDefinition) {
                        try fileWriter.writeProjection(typeDefinition)
                    }

                    let instanciationsByName = try instanciations
                        .map { (key: try swiftProjection.toProjectionInstanciationTypeName(genericArgs: $0), value: $0) }
                        .sorted { $0.key < $1.key }
                    for (_, genericArgs) in instanciationsByName {
                        try fileWriter.writeProjection(typeDefinition, genericArgs: genericArgs)
                    }
                }
            }
        }
    }

    private static func loadAssemblyAndDocumentation(
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
                    if FileManager.default.fileExists(atPath: sideBySideDocsPath) {
                        docs = try AssemblyDocumentation(readingFileAtPath: languageNestedDocsPath)
                    }
                }
            }
        }
        return (assembly, docs)
    }

    static func getModule(assemblyName: String, moduleMapFile: ModuleMapFile?) -> (name: String, mapping: ModuleMapFile.Module?) {
        if let moduleMapFile {
            for (moduleName, module) in moduleMapFile.modules {
                if module.assemblies.contains(assemblyName) {
                    return (moduleName, module)
                }
            }
        }

        return (assemblyName, nil)
    }

    static func isIncluded(fullName: String, filters: [String]?) -> Bool {
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
}

// let cabiWriter = CAbi.SourceFileWriter(output: StdoutOutputStream())

// for typeDefinition in assembly.definedTypes {
//     guard typeDefinition.namespace == namespace,
//         typeDefinition.visibility == .public,
//         typeDefinition.genericParams.isEmpty else { continue }

//     if let structDefinition = typeDefinition as? StructDefinition {
//         try? cabiWriter.writeStruct(structDefinition)
//     }
//     else if let enumDefinition = typeDefinition as? EnumDefinition {
//         try? cabiWriter.writeEnum(enumDefinition)
//     }
//     else if let interfaceDefinition = typeDefinition as? InterfaceDefinition {
//         try? cabiWriter.writeInterface(interfaceDefinition, genericArgs: [])
//     }
// }