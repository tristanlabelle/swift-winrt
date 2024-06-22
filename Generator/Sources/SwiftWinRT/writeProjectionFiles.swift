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

        for typeDefinition in module.typeDefinitions + Array(module.closedGenericTypesByDefinition.keys) {
            guard try hasSwiftDefinition(typeDefinition) else { continue }

            let compactNamespace = SwiftProjection.toCompactNamespace(typeDefinition.namespace!)
            let assemblyNamespaceDirectoryPath = "\(assemblyModuleDirectoryPath)\\\(compactNamespace)"

            if module.hasTypeDefinition(typeDefinition) {
                let typeName = try projection.toTypeName(typeDefinition)
                try writeTypeDefinitionFile(typeDefinition, module: module, toPath: "\(assemblyNamespaceDirectoryPath)\\\(typeName).swift")

                let extensionFileBytes: [UInt8]?
                switch typeDefinition.fullName {
                    case "Windows.Foundation.Collections.IIterable`1":
                        extensionFileBytes = PackageResources.WindowsFoundationCollections_IIterable_swift
                    case "Windows.Foundation.Collections.IVector`1":
                        extensionFileBytes = PackageResources.WindowsFoundationCollections_IVector_swift
                    case "Windows.Foundation.Collections.IVectorView`1":
                        extensionFileBytes = PackageResources.WindowsFoundationCollections_IVectorView_swift
                    default:
                        extensionFileBytes = nil
                }
                if let extensionFileBytes {
                    try Data(extensionFileBytes).write(to: URL(fileURLWithPath:
                        "\(assemblyNamespaceDirectoryPath)\\\(typeName)+extras.swift",
                        isDirectory: false))
                }
            }

            if (typeDefinition as? ClassDefinition)?.isStatic != true,
                !typeDefinition.isValueType || SupportModules.WinRT.getBuiltInTypeKind(typeDefinition) != .definitionAndProjection {
                let typeName = try projection.toTypeName(typeDefinition)
                try writeABIProjectionConformanceFile(typeDefinition, module: module,
                    toPath: "\(assemblyNamespaceDirectoryPath)\\Projections\\\(typeName)+Projection.swift")
            }
        }

        for abiType in try getABITypes(module: module) {
            guard let namespace = abiType.definition.namespace else { continue }
            let compactNamespace = SwiftProjection.toCompactNamespace(namespace)
            let mangledName = try CAbi.mangleName(type: abiType)
            try writeCOMInteropExtensionFile(abiType: abiType, module: module,
                toPath: "\(assemblyModuleDirectoryPath)\\\(compactNamespace)\\COMInterop\\\(mangledName).swift")
        }

        if !module.flattenNamespaces {
            let typeDefinitionsByNamespace = Dictionary(grouping: module.typeDefinitions, by: { $0.namespace })
            for (namespace, typeDefinitions) in typeDefinitionsByNamespace {
                let typeDefinitions = try typeDefinitions.filter(hasSwiftDefinition)
                guard !typeDefinitions.isEmpty else { continue }

                let compactNamespace = SwiftProjection.toCompactNamespace(namespace!)
                let namespaceAliasesPath = "\(moduleRootPath)\\Namespaces\\\(compactNamespace)\\Aliases.swift"
                try writeNamespaceAliasesFile(typeDefinitions: typeDefinitions, module: module, toPath: namespaceAliasesPath)
            }
        }
    }
}

fileprivate func hasSwiftDefinition(_ typeDefinition: TypeDefinition) throws -> Bool {
    return try SupportModules.WinRT.getBuiltInTypeKind(typeDefinition) != .special
        && !typeDefinition.hasAttribute(ApiContractAttribute.self)
        && typeDefinition.isPublic
}

fileprivate func writeTypeDefinitionFile(_ typeDefinition: TypeDefinition, module: SwiftProjection.Module, toPath path: String) throws {
    let writer = SwiftSourceFileWriter(output: FileTextOutputStream(path: path, directoryCreation: .ancestors))
    writeGeneratedCodePreamble(to: writer)
    writeModulePreamble(module, to: writer)
    try writeTypeDefinition(typeDefinition, projection: module.projection, to: writer)
}

fileprivate func writeABIProjectionConformanceFile(_ typeDefinition: TypeDefinition, module: SwiftProjection.Module, toPath path: String) throws {
    let writer = SwiftSourceFileWriter(output: FileTextOutputStream(path: path, directoryCreation: .ancestors))
    writeGeneratedCodePreamble(to: writer)
    writeModulePreamble(module, to: writer)

    if module.hasTypeDefinition(typeDefinition) {
        try writeABIProjectionConformance(typeDefinition, genericArgs: nil, projection: module.projection, to: writer)
    }

    for genericArgs in module.closedGenericTypesByDefinition[typeDefinition] ?? [] {
        let boundType = typeDefinition.bindType(genericArgs: genericArgs)
        writer.writeMarkComment(try WinRTTypeName.from(type: boundType).description)
        try writeABIProjectionConformance(typeDefinition, genericArgs: genericArgs, projection: module.projection, to: writer)
    }
}

fileprivate func getABITypes(module: SwiftProjection.Module) throws -> [BoundType] {
    var abiTypes = [BoundType]()
    for typeDefinition in module.typeDefinitions {
        guard typeDefinition.genericArity == 0 else { continue }
        guard typeDefinition is InterfaceDefinition || typeDefinition is DelegateDefinition else { continue }
        abiTypes.append(typeDefinition.bindType())
    }

    for (typeDefinition, instantiations) in module.closedGenericTypesByDefinition {
        // IReference<T> is implemented generically in the support module.
        if typeDefinition.namespace == "Windows.Foundation", typeDefinition.name == "IReference`1" { continue }
        for genericArgs in instantiations {
            abiTypes.append(typeDefinition.bindType(genericArgs: genericArgs))
        }
    }

    return abiTypes
}

fileprivate func writeCOMInteropExtensionFile(abiType: BoundType, module: SwiftProjection.Module, toPath path: String) throws {
    let writer = SwiftSourceFileWriter(output: FileTextOutputStream(path: path, directoryCreation: .ancestors))
    writeGeneratedCodePreamble(to: writer)
    writeModulePreamble(module, to: writer)
    try writeCOMInteropExtension(abiType: abiType, projection: module.projection, to: writer)
}

internal func writeNamespaceAliasesFile(typeDefinitions: [TypeDefinition], module: SwiftProjection.Module, toPath path: String) throws {
    let writer = SwiftSourceFileWriter(output: FileTextOutputStream(path: path, directoryCreation: .ancestors))
    writeGeneratedCodePreamble(to: writer)
    writer.writeImport(module: module.name)

    for typeDefinition in typeDefinitions.sorted(by: { $0.fullName < $1.fullName }) {
        guard typeDefinition.isPublic else { continue }

        try writeNamespaceAlias(typeDefinition, projection: module.projection, to: writer)
    }
}
