import CodeWriters
import Collections
import DotNetMetadata
import DotNetXMLDocs
import Foundation
import ProjectionGenerator
import WindowsMetadata

func writeProjection(_ projection: SwiftProjection, generateCommand: GenerateCommand) throws {
    let abiModuleDirectoryPath = "\(generateCommand.out)\\\(projection.abiModuleName)"
    try FileManager.default.createDirectory(atPath: abiModuleDirectoryPath, withIntermediateDirectories: true)

    for module in projection.modulesByShortName.values {
        let moduleRootPath = "\(generateCommand.out)\\\(module.shortName)"
        let assemblyModuleDirectoryPath = "\(moduleRootPath)\\Assembly"

        try writeCAbiFile(module: module, toPath: "\(abiModuleDirectoryPath)\\\(module.shortName).h")

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

fileprivate func writeCAbiFile(module: SwiftProjection.Module, toPath path: String) throws {
    var boundTypesByMangledName = OrderedDictionary<String, BoundType>()
    for (_, typeDefinitions) in module.typeDefinitionsByNamespace {
        for typeDefinition in typeDefinitions {
            guard typeDefinition.genericArity == 0 else { continue }
            guard !(typeDefinition is ClassDefinition) else { continue }
            let type = typeDefinition.bindType()
            let mangledName = try CAbi.mangleName(type: type)
            boundTypesByMangledName[mangledName] = type
        }
    }

    for (typeDefinition, instanciations) in module.closedGenericTypesByDefinition {
        for genericArgs in instanciations {
            let type = typeDefinition.bindType(genericArgs: genericArgs)
            let mangledName = try CAbi.mangleName(type: type)
            boundTypesByMangledName[mangledName] = type
        }
    }

    var sourceFileWriter = CSourceFileWriter(output: FileTextOutputStream(path: path))

    for reference in module.references {
        sourceFileWriter.writeInclude(header: "\(reference.shortName).h", local: true)
    }

    // Forward declare all interfaces and structs
    for (mangledName, boundType) in boundTypesByMangledName {
        sourceFileWriter.writeForwardDeclaration(
            kind: boundType.definition is EnumDefinition ? .enum : .struct,
            name: mangledName)
    }

    // Write all interfaces and delegates
    for (_, boundType) in boundTypesByMangledName {
        switch boundType.definition {
            case let enumDefinition as EnumDefinition:
                try CAbi.writeEnum(enumDefinition, to: &sourceFileWriter)
            case let structDefinition as StructDefinition:
                try CAbi.writeStruct(structDefinition, to: &sourceFileWriter)
            case let interfaceDefinition as InterfaceDefinition:
                try CAbi.writeInterface(interfaceDefinition, genericArgs: boundType.genericArgs, to: &sourceFileWriter)
            default:
                break
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