import DotNetMetadata
import DotNetXMLDocs
import Foundation
import ProjectionGenerator
import WindowsMetadata

func writeProjection(_ projection: SwiftProjection, generateCommand: GenerateCommand) throws {
    for module in projection.modulesByShortName.values {
        let moduleRootPath = "\(generateCommand.out)\\\(module.shortName)"
        let assemblyModuleDirectoryPath = "\(moduleRootPath)\\Assembly"

        for (namespace, typeDefinitions) in module.typeDefinitionsByNamespace {
            let compactNamespace = SwiftProjection.toCompactNamespace(namespace)
            print("Generating types for namespace \(namespace)...")

            let namespaceModuleDirectoryPath = "\(moduleRootPath)\\Namespaces\\\(compactNamespace)"
            let namespaceAliasesPath = "\(namespaceModuleDirectoryPath)\\Aliases.swift"
            try FileManager.default.createDirectory(atPath: namespaceModuleDirectoryPath, withIntermediateDirectories: true)
            let aliasesWriter = SwiftNamespaceModuleFileWriter(path: namespaceAliasesPath, module: module)

            for typeDefinition in typeDefinitions.sorted(by: { $0.fullName < $1.fullName }) {
                // Some types have special handling and should not have their projection code generated
                guard typeDefinition.fullName != "Windows.Foundation.HResult" else { continue }
                guard typeDefinition.fullName != "Windows.Foundation.EventRegistrationToken" else { continue }
                guard try !typeDefinition.hasAttribute(ApiContractAttribute.self) else { continue }

                try writeProjectionSwiftFile(module: module, typeDefinition: typeDefinition, closedGenericArgs: nil,
                    writeDefinition: true, assemblyModuleDirectoryPath: assemblyModuleDirectoryPath)

                if typeDefinition.isPublic { try aliasesWriter.writeAliases(typeDefinition) }
            }
        }

        let closedGenericTypesByDefinition = module.closedGenericTypesByDefinition
            .sorted { $0.key.fullName < $1.key.fullName }
        for (typeDefinition, instanciations) in closedGenericTypesByDefinition {
            if !module.hasTypeDefinition(typeDefinition) {
                try writeProjectionSwiftFile(module: module, typeDefinition: typeDefinition, closedGenericArgs: nil,
                    writeDefinition: false, assemblyModuleDirectoryPath: assemblyModuleDirectoryPath)
            }

            let instanciationsByName = try instanciations
                .map { (key: try SwiftProjection.toProjectionInstanciationTypeName(genericArgs: $0), value: $0) }
                .sorted { $0.key < $1.key }
            for (_, genericArgs) in instanciationsByName {
                try writeProjectionSwiftFile(module: module, typeDefinition: typeDefinition, closedGenericArgs: genericArgs,
                    writeDefinition: false, assemblyModuleDirectoryPath: assemblyModuleDirectoryPath)
            }
        }
    }
}

fileprivate func writeProjectionSwiftFile(
        module: SwiftProjection.Module,
        typeDefinition: TypeDefinition,
        closedGenericArgs: [TypeNode]? = nil,
        writeDefinition: Bool,
        assemblyModuleDirectoryPath: String) throws {

    let compactNamespace = SwiftProjection.toCompactNamespace(typeDefinition.namespace!)
    let namespaceDirectoryPath = "\(assemblyModuleDirectoryPath)\\\(compactNamespace)"

    var fileName = typeDefinition.nameWithoutGenericSuffix
    if let closedGenericArgs = closedGenericArgs {
        fileName += "+"
        fileName += try SwiftProjection.toProjectionInstanciationTypeName(genericArgs: closedGenericArgs)
    }
    fileName += ".swift"

    let filePath = "\(namespaceDirectoryPath)\\\(fileName)"
    try FileManager.default.createDirectory(atPath: namespaceDirectoryPath, withIntermediateDirectories: true)
    let projectionWriter = SwiftAssemblyModuleFileWriter(path: filePath, module: module, importAbiModule: true)

    if writeDefinition { try projectionWriter.writeTypeDefinition(typeDefinition) }
    try projectionWriter.writeProjection(typeDefinition, genericArgs: closedGenericArgs)
}