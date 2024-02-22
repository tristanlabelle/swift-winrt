import CodeWriters
import Collections
import DotNetMetadata
import DotNetXMLDocs
import Foundation
import ProjectionModel
import WindowsMetadata

internal func writeProjectionFiles(_ projection: SwiftProjection, generateCommand: GenerateCommand) throws {
    let abiModuleDirectoryPath = "\(generateCommand.outputDirectoryPath)\\\(projection.abiModuleName)"
    let abiModuleIncludeDirectoryPath = "\(abiModuleDirectoryPath)\\include"
    CAbi.writeCoreHeader(to: FileTextOutputStream(path: "\(abiModuleIncludeDirectoryPath)\\_Core.h", directoryCreation: .ancestors))

    for module in projection.modulesByName.values {
        guard !module.isEmpty else { continue }

        let moduleRootPath = "\(generateCommand.outputDirectoryPath)\\\(module.name)"
        let assemblyModuleDirectoryPath = "\(moduleRootPath)\\Assembly"

        try writeCAbiFile(module: module, toPath: "\(abiModuleIncludeDirectoryPath)\\\(module.name).h")
        try writeCOMInteropExtensionsFile(module: module, toPath: "\(assemblyModuleDirectoryPath)\\COMInterop.swift")
        try writeABIProjectionsFile(module: module, toPath: "\(assemblyModuleDirectoryPath)\\ABIProjections.swift")

        for (namespace, typeDefinitions) in module.typeDefinitionsByNamespace {
            let compactNamespace = SwiftProjection.toCompactNamespace(namespace)
            print("Generating types for namespace \(namespace)...")

            var typeDefinitions = Array(typeDefinitions)
            try typeDefinitions.removeAll {
                try !$0.isPublic || SupportModule.hasBuiltInProjection($0) || $0.hasAttribute(ApiContractAttribute.self)
            }
            typeDefinitions.sort { $0.fullName < $1.fullName }

            // Write the type definition file
            for typeDefinition in typeDefinitions {
                let filePath = "\(assemblyModuleDirectoryPath)\\\(compactNamespace)\\\(typeDefinition.nameWithoutGenericSuffix).swift"
                let writer = SwiftSourceFileWriter(output: FileTextOutputStream(path: filePath, directoryCreation: .ancestors))
                writeGeneratedCodePreamble(to: writer)
                writeModulePreamble(module, to: writer)
                try writeTypeDefinition(typeDefinition, projection: module.projection, to: writer)
            }

            // Write the namespace aliases file
            if !module.flattenNamespaces {
                let namespaceAliasesPath = "\(moduleRootPath)\\Namespaces\\\(compactNamespace)\\Aliases.swift"
                try writeNamespaceAliasesFile(typeDefinitions: typeDefinitions, module: module, toPath: namespaceAliasesPath)
            }
        }
    }
}
