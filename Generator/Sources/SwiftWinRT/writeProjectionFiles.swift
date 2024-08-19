import CodeWriters
import Collections
import DotNetMetadata
import DotNetXMLDocs
import Foundation
import ProjectionModel
import WindowsMetadata

internal func writeProjectionFiles(_ projection: SwiftProjection, directoryPath: String, generateCMakeLists: Bool) throws {
    for module in projection.modulesByName.values {
        guard !module.isEmpty else { continue }
        try writeModuleFiles(module,
            directoryPath: "\(directoryPath)\\\(module.name)",
            generateCMakeLists: generateCMakeLists)
    }

    if generateCMakeLists {
        let writer = CMakeListsWriter(output: FileTextOutputStream(
            path: "\(directoryPath)\\CMakeLists.txt",
            directoryCreation: .ancestors))
        for module in projection.modulesByName.values {
            guard !module.isEmpty else { continue }
            writer.writeAddSubdirectory(module.name)
        }
    }
}

fileprivate func writeModuleFiles(_ module: SwiftProjection.Module, directoryPath: String, generateCMakeLists: Bool) throws {
    try writeABIModule(module, directoryPath: "\(directoryPath)\\ABI", generateCMakeLists: generateCMakeLists)
    try writeAssemblyModuleFiles(module, directoryPath: "\(directoryPath)\\Assembly", generateCMakeLists: generateCMakeLists)
    if !module.flattenNamespaces {
        try writeNamespaceModuleFiles(module, directoryPath: "\(directoryPath)\\Namespaces", generateCMakeLists: generateCMakeLists)
    }

    if generateCMakeLists {
        let writer = CMakeListsWriter(output: FileTextOutputStream(
            path: "\(directoryPath)\\CMakeLists.txt",
            directoryCreation: .ancestors))
        writer.writeAddSubdirectory("ABI")
        writer.writeAddSubdirectory("Assembly")
        if !module.flattenNamespaces {
            writer.writeAddSubdirectory("Namespaces")
        }
    }
}

fileprivate func writeAssemblyModuleFiles(_ module: SwiftProjection.Module, directoryPath: String, generateCMakeLists: Bool) throws {
    var cmakeSources: [String] = []
    for typeDefinition in module.typeDefinitions + Array(module.genericInstantiationsByDefinition.keys) {
        guard try hasSwiftDefinition(typeDefinition) else { continue }

        let compactNamespace = SwiftProjection.toCompactNamespace(typeDefinition.namespace!)
        let assemblyNamespaceDirectoryPath = "\(directoryPath)\\\(compactNamespace)"

        if module.hasTypeDefinition(typeDefinition) {
            let typeName = try module.projection.toTypeName(typeDefinition)
            cmakeSources.append("\(compactNamespace)/\(typeName).swift")
            try writeTypeDefinitionFile(typeDefinition, module: module, toPath: "\(assemblyNamespaceDirectoryPath)\\\(typeName).swift")

            if let extensionFileBytes = try getExtensionFileBytes(typeDefinition: typeDefinition) {
                cmakeSources.append("\(compactNamespace)/\(typeName)+extras.swift")
                try Data(extensionFileBytes).write(to: URL(fileURLWithPath:
                    "\(assemblyNamespaceDirectoryPath)\\\(typeName)+extras.swift",
                    isDirectory: false))
            }
        }

        if (typeDefinition as? ClassDefinition)?.isStatic != true,
            !typeDefinition.isValueType || SupportModules.WinRT.getBuiltInTypeKind(typeDefinition) != .definitionAndProjection {
            let typeName = try module.projection.toTypeName(typeDefinition)
            cmakeSources.append("\(compactNamespace)/Projections/\(typeName)+Projection.swift")
            try writeABIProjectionConformanceFile(typeDefinition, module: module,
                toPath: "\(assemblyNamespaceDirectoryPath)\\Projections\\\(typeName)+Projection.swift")
        }
    }

    for abiType in try getABITypes(module: module) {
        guard let namespace = abiType.definition.namespace else { continue }
        let compactNamespace = SwiftProjection.toCompactNamespace(namespace)
        let mangledName = try CAbi.mangleName(type: abiType)
        cmakeSources.append("\(compactNamespace)/COMInterop/\(mangledName).swift")
        try writeCOMInteropExtensionFile(abiType: abiType, module: module,
            toPath: "\(directoryPath)\\\(compactNamespace)\\COMInterop\\\(mangledName).swift")
    }

    if generateCMakeLists {
        let writer = CMakeListsWriter(output: FileTextOutputStream(
            path: "\(directoryPath)\\CMakeLists.txt",
            directoryCreation: .ancestors))
        cmakeSources.sort()
        writer.writeAddLibrary(module.name, .static, cmakeSources)
        writer.writeTargetLinkLibraries(
            module.name, .public,
            [ SupportModules.WinRT.moduleName, module.abiModuleName ] + module.references.map { $0.name })
    }
}

fileprivate func writeNamespaceModuleFiles(_ module: SwiftProjection.Module, directoryPath: String, generateCMakeLists: Bool) throws {
    let typeDefinitionsByNamespace = Dictionary(grouping: module.typeDefinitions, by: { $0.namespace })

    var compactNamespaces: [String] = [] 
    for (namespace, typeDefinitions) in typeDefinitionsByNamespace {
        let typeDefinitions = try typeDefinitions.filter(hasSwiftDefinition)
        guard !typeDefinitions.isEmpty else { continue }
        guard let namespace else { continue }

        let compactNamespace = SwiftProjection.toCompactNamespace(namespace)
        compactNamespaces.append(compactNamespace)
        let namespaceAliasesPath = "\(directoryPath)\\\(compactNamespace)\\Aliases.swift"
        try writeNamespaceAliasesFile(typeDefinitions: typeDefinitions, module: module, toPath: namespaceAliasesPath)

        if generateCMakeLists {
            let writer = CMakeListsWriter(output: FileTextOutputStream(
                path: "\(directoryPath)\\\(compactNamespace)\\CMakeLists.txt",
                directoryCreation: .ancestors))
            let namespaceModuleName = module.getNamespaceModuleName(namespace: namespace)
            writer.writeAddLibrary(namespaceModuleName, .static, ["Aliases.swift"])
            writer.writeTargetLinkLibraries(namespaceModuleName, .public, [module.name])
        }
    }

    if generateCMakeLists, !compactNamespaces.isEmpty {
        let writer = CMakeListsWriter(output: FileTextOutputStream(
            path: "\(directoryPath)\\CMakeLists.txt",
            directoryCreation: .ancestors))
        for compactNamespace in compactNamespaces {
            writer.writeAddSubdirectory(compactNamespace)
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

    for genericArgs in module.genericInstantiationsByDefinition[typeDefinition] ?? [] {
        let boundType = typeDefinition.bindType(genericArgs: genericArgs)
        writer.writeMarkComment(try WinRTTypeName.from(type: boundType).description)
        try writeABIProjectionConformance(typeDefinition, genericArgs: genericArgs, projection: module.projection, to: writer)
    }
}

fileprivate func getExtensionFileBytes(typeDefinition: TypeDefinition) throws -> [UInt8]? {
    switch typeDefinition.fullName {
        case "Windows.Foundation.IAsyncAction":
            return PackageResources.WindowsFoundation_IAsyncAction_swift
        case "Windows.Foundation.IAsyncActionWithProgress`1":
            return PackageResources.WindowsFoundation_IAsyncActionWithProgress_swift
        case "Windows.Foundation.IAsyncOperation`1":
            return PackageResources.WindowsFoundation_IAsyncOperation_swift
        case "Windows.Foundation.IAsyncOperationWithProgress`2":
            return PackageResources.WindowsFoundation_IAsyncOperationWithProgress_swift
        case "Windows.Foundation.IMemoryBuffer":
            return PackageResources.WindowsFoundation_IMemoryBuffer_swift
        case "Windows.Foundation.IMemoryBufferReference":
            return PackageResources.WindowsFoundation_IMemoryBufferReference_swift
        case "Windows.Foundation.MemoryBuffer":
            return PackageResources.WindowsFoundation_MemoryBuffer_swift
        case "Windows.Foundation.Collections.IIterable`1":
            return PackageResources.WindowsFoundationCollections_IIterable_swift
        case "Windows.Foundation.Collections.IVector`1":
            return PackageResources.WindowsFoundationCollections_IVector_swift
        case "Windows.Foundation.Collections.IVectorView`1":
            return PackageResources.WindowsFoundationCollections_IVectorView_swift
        case "Windows.Storage.Streams.Buffer":
            return PackageResources.WindowsStorageStreams_Buffer_swift
        case "Windows.Storage.Streams.IBuffer":
            return PackageResources.WindowsStorageStreams_IBuffer_swift
        default:
            return nil
    }
}

fileprivate func getABITypes(module: SwiftProjection.Module) throws -> [BoundType] {
    var abiTypes = [BoundType]()
    for typeDefinition in module.typeDefinitions {
        guard typeDefinition.genericArity == 0 else { continue }
        guard typeDefinition is InterfaceDefinition || typeDefinition is DelegateDefinition else { continue }
        abiTypes.append(typeDefinition.bindType())
    }

    for (typeDefinition, instantiations) in module.genericInstantiationsByDefinition {
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
