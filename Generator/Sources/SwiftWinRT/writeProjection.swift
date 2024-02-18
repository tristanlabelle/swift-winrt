import CodeWriters
import Collections
import DotNetMetadata
import DotNetXMLDocs
import Foundation
import ProjectionGenerator
import WindowsMetadata

func writeProjection(_ projection: SwiftProjection, generateCommand: GenerateCommand) throws {
    let abiModuleDirectoryPath = "\(generateCommand.outputDirectoryPath)\\\(projection.abiModuleName)"
    let abiModuleIncludeDirectoryPath = "\(abiModuleDirectoryPath)\\include"
    CAbi.writeCoreHeader(to: FileTextOutputStream(path: "\(abiModuleIncludeDirectoryPath)\\_Core.h", directoryCreation: .ancestors))

    for module in projection.modulesByName.values {
        guard !module.isEmpty else { continue }

        let moduleRootPath = "\(generateCommand.outputDirectoryPath)\\\(module.name)"
        let assemblyModuleDirectoryPath = "\(moduleRootPath)\\Assembly"

        try writeCAbiFile(module: module, toPath: "\(abiModuleIncludeDirectoryPath)\\\(module.name).h")
        try writeCOMInteropExtensionsFile(module: module, toPath: "\(assemblyModuleDirectoryPath)\\_COMInterop.swift")

        for (namespace, typeDefinitions) in module.typeDefinitionsByNamespace {
            let compactNamespace = SwiftProjection.toCompactNamespace(namespace)
            print("Generating types for namespace \(namespace)...")

            let aliasesWriter: SwiftSourceFileWriter?
            if module.flattenNamespaces {
                aliasesWriter = nil
            }
            else {
                let namespaceModuleDirectoryPath = "\(moduleRootPath)\\Namespaces\\\(compactNamespace)"
                let namespaceAliasesPath = "\(namespaceModuleDirectoryPath)\\Aliases.swift"
                let writer = SwiftSourceFileWriter(output: FileTextOutputStream(path: namespaceAliasesPath, directoryCreation: .ancestors))
                writeGeneratedCodePreamble(to: writer)
                writer.writeImport(module: module.name)
                aliasesWriter = writer
            }

            for typeDefinition in typeDefinitions.sorted(by: { $0.fullName < $1.fullName }) {
                guard typeDefinition.isPublic else { continue }

                // Some types have special handling and should not have their projection code generated
                if typeDefinition.namespace == "Windows.Foundation" {
                    guard typeDefinition.name != "EventRegistrationToken" else { continue }
                    guard typeDefinition.name != "HResult" else { continue }
                }
                guard try !typeDefinition.hasAttribute(ApiContractAttribute.self) else { continue }

                try writeProjectionSwiftFile(module: module, typeDefinition: typeDefinition, closedGenericArgs: nil,
                    assemblyModuleDirectoryPath: assemblyModuleDirectoryPath)

                if let aliasesWriter { try writeNamespaceAlias(typeDefinition, projection: projection, to: aliasesWriter) }
            }
        }

        let closedGenericTypesByDefinition = module.closedGenericTypesByDefinition
            .sorted { $0.key.fullName < $1.key.fullName }
        for (typeDefinition, instanciations) in closedGenericTypesByDefinition {
            // Some types have special handling and should not have their projection code generated
            if typeDefinition.namespace == "Windows.Foundation" {
                guard typeDefinition.name != "IReference`1" else { continue }
            }

            let instanciationsByName = try instanciations
                .map { (key: try SwiftProjection.toProjectionInstantiationTypeName(genericArgs: $0), value: $0) }
                .sorted { $0.key < $1.key }
            for (_, genericArgs) in instanciationsByName {
                try writeProjectionSwiftFile(module: module, typeDefinition: typeDefinition, closedGenericArgs: genericArgs,
                    assemblyModuleDirectoryPath: assemblyModuleDirectoryPath)
            }
        }
    }
}

fileprivate func writeProjectionSwiftFile(
        module: SwiftProjection.Module,
        typeDefinition: TypeDefinition,
        closedGenericArgs: [TypeNode]? = nil,
        assemblyModuleDirectoryPath: String) throws {
    let compactNamespace = SwiftProjection.toCompactNamespace(typeDefinition.namespace!)
    let namespaceDirectoryPath = "\(assemblyModuleDirectoryPath)\\\(compactNamespace)"

    var fileNameWithoutExtension = typeDefinition.nameWithoutGenericSuffix
    if let closedGenericArgs = closedGenericArgs {
        fileNameWithoutExtension += "+"
        fileNameWithoutExtension += try SwiftProjection.toProjectionInstantiationTypeName(genericArgs: closedGenericArgs)
    }

    let filePath = "\(namespaceDirectoryPath)\\\(fileNameWithoutExtension).swift"
    let writer = SwiftSourceFileWriter(output: FileTextOutputStream(path: filePath, directoryCreation: .ancestors))
    writeGeneratedCodePreamble(to: writer)
    writeModulePreamble(module, to: writer)

    if closedGenericArgs?.isEmpty != false {
        try writeTypeDefinition(typeDefinition, projection: module.projection, to: writer)
    }
    
    try writeABIProjectionConformance(typeDefinition, genericArgs: closedGenericArgs, projection: module.projection, to: writer)
}
