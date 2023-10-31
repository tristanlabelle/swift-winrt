import DotNetMetadata
import DotNetXMLDocs
import Foundation
import ProjectionGenerator
import WindowsMetadata

func writeProjection(_ projection: SwiftProjection, generateCommand: GenerateCommand) throws {
    for module in projection.modulesByShortName.values {
        let moduleRootPath = "\(generateCommand.out)\\\(module.shortName)"
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
                    .map { (key: try projection.toProjectionInstanciationTypeName(genericArgs: $0), value: $0) }
                    .sorted { $0.key < $1.key }
                for (_, genericArgs) in instanciationsByName {
                    try fileWriter.writeProjection(typeDefinition, genericArgs: genericArgs)
                }
            }
        }
    }
}