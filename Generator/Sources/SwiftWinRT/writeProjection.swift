import CodeWriters
import Collections
import DotNetMetadata
import DotNetXMLDocs
import Foundation
import ProjectionGenerator
import WindowsMetadata

func writeProjection(_ projection: SwiftProjection, generateCommand: GenerateCommand) throws {
    let abiModuleDirectoryPath = "\(generateCommand.out)\\\(projection.abiModuleName)"
    let abiModuleIncludeDirectoryPath = "\(abiModuleDirectoryPath)\\include"
    try FileManager.default.createDirectory(atPath: abiModuleIncludeDirectoryPath, withIntermediateDirectories: true)

    CAbi.writeCoreHeader(to: FileTextOutputStream(path: "\(abiModuleIncludeDirectoryPath)\\_Core.h"))

    for module in projection.modulesByShortName.values {
        let moduleRootPath = "\(generateCommand.out)\\\(module.shortName)"
        let assemblyModuleDirectoryPath = "\(moduleRootPath)\\Assembly"

        try writeCAbiFile(module: module, toPath: "\(abiModuleIncludeDirectoryPath)\\\(module.shortName).h")

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
    var typesByMangledName = OrderedDictionary<String, BoundType>()
    for (_, typeDefinitions) in module.typeDefinitionsByNamespace {
        for typeDefinition in typeDefinitions {
            guard typeDefinition.genericArity == 0 else { continue }

            // For classes, use the default interface iff it is exclusive
            let type: BoundType
            if let classDefinition = typeDefinition as? ClassDefinition {
                guard !classDefinition.isStatic else { continue }
                guard let defaultInterface = try DefaultAttribute.getDefaultInterface(classDefinition) else { throw WinMDError.missingAttribute }
                guard let exclusiveTo = try defaultInterface.definition.findAttribute(ExclusiveToAttribute.self), exclusiveTo == classDefinition else { continue }

                type = defaultInterface.asBoundType
            }
            else {
                type = typeDefinition.bindType()
            }

            let mangledName = try CAbi.mangleName(type: type)
            typesByMangledName[mangledName] = type
        }
    }

    for (typeDefinition, instanciations) in module.closedGenericTypesByDefinition {
        for genericArgs in instanciations {
            let type = typeDefinition.bindType(genericArgs: genericArgs)
            let mangledName = try CAbi.mangleName(type: type)
            typesByMangledName[mangledName] = type
        }
    }

    let cHeaderWriter = CSourceFileWriter(output: FileTextOutputStream(path: path))
    cHeaderWriter.writeInclude(pathSpec: "_Core.h", kind: .doubleQuotes)

    for reference in module.references {
        cHeaderWriter.writeInclude(pathSpec: "\(reference.shortName).h", kind: .doubleQuotes)
    }

    // Forward declare all interfaces and structs
    for (_, type) in typesByMangledName {
        try CAbi.writeForwardDeclaration(type: type, to: cHeaderWriter)
    }

    // Write all interfaces and delegates
    for (_, type) in typesByMangledName {
        switch type.definition {
            case let enumDefinition as EnumDefinition:
                try CAbi.writeEnum(enumDefinition, to: cHeaderWriter)
            case let structDefinition as StructDefinition:
                try CAbi.writeStruct(structDefinition, to: cHeaderWriter)
            case let interfaceDefinition as InterfaceDefinition:
                try CAbi.writeCOMInterface(interfaceDefinition, genericArgs: type.genericArgs, to: cHeaderWriter)
            case let delegateDefinition as DelegateDefinition:
                try CAbi.writeCOMInterface(delegateDefinition, genericArgs: type.genericArgs, to: cHeaderWriter)
            default:
                fatalError("Unexpected type definition kind \(type)")
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