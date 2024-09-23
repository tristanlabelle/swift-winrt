import CodeWriters
import Collections
import DotNetMetadata
import DotNetXMLDocs
import Foundation
import ProjectionModel
import WindowsMetadata

internal func writeProjectionFiles(
        _ projection: Projection,
        directoryPath: String,
        cmakeOptions: CMakeOptions?) throws {
    for module in projection.modulesByName.values {
        guard !module.isEmpty else { continue }
        print("Generating projection for \(module.name)...")
        try writeModuleFiles(module,
            directoryPath: "\(directoryPath)\\\(module.name)",
            cmakeOptions: cmakeOptions)
    }

    if cmakeOptions != nil {
        let writer = CMakeListsWriter(output: FileTextOutputStream(
            path: "\(directoryPath)\\CMakeLists.txt",
            directoryCreation: .ancestors))
        for module in projection.modulesByName.values {
            guard !module.isEmpty else { continue }
            writer.writeAddSubdirectory(module.name)
        }
    }
}

fileprivate func writeModuleFiles(
        _ module: Module,
        directoryPath: String,
        cmakeOptions: CMakeOptions?) throws {
    try writeABIModule(module, directoryPath: "\(directoryPath)\\ABI", cmakeOptions: cmakeOptions)

    try writeSwiftModuleFiles(module, directoryPath: "\(directoryPath)\\Projection", cmakeOptions: cmakeOptions)

    if !module.flattenNamespaces {
        try writeNamespaceModuleFiles(module, directoryPath: "\(directoryPath)\\Namespaces", cmakeOptions: cmakeOptions)
    }

    if cmakeOptions != nil {
        let writer = CMakeListsWriter(output: FileTextOutputStream(
            path: "\(directoryPath)\\CMakeLists.txt",
            directoryCreation: .ancestors))
        writer.writeAddSubdirectory("ABI")
        writer.writeAddSubdirectory("Projection")
        if !module.flattenNamespaces {
            writer.writeAddSubdirectory("Namespaces")
        }
    }
}

fileprivate func writeSwiftModuleFiles(_ module: Module, directoryPath: String, cmakeOptions: CMakeOptions?) throws {
    for typeDefinition in module.typeDefinitions + Array(module.genericInstantiationsByDefinition.keys) {
        // All WinRT types should have namespaces
        guard let namespace = typeDefinition.namespace else { continue }

        let compactNamespace = Projection.toCompactNamespace(namespace)
        let namespaceDirectoryPath = "\(directoryPath)\\\(compactNamespace)"
        let typeName = try module.projection.toTypeName(typeDefinition)

        // Write the COM interop extensions
        if typeDefinition is InterfaceDefinition || typeDefinition is DelegateDefinition {
            let fileName = "SWRT_\(typeName).swift"
            _ = try writeCOMInteropExtensionFile(typeDefinition: typeDefinition, module: module,
                    toPath: "\(directoryPath)\\\(compactNamespace)\\COMInterop\\\(fileName)")
        }

        guard try hasSwiftDefinition(typeDefinition) else { continue }

        if module.hasTypeDefinition(typeDefinition) {
            try writeTypeDefinitionFile(typeDefinition, module: module, toPath: "\(namespaceDirectoryPath)\\\(typeName).swift")

            if let extensionFileBytes = try getExtensionFileBytes(typeDefinition: typeDefinition) {
                try Data(extensionFileBytes).write(to: URL(fileURLWithPath:
                    "\(namespaceDirectoryPath)\\\(typeName)+extras.swift",
                    isDirectory: false))
            }
        }

        if (typeDefinition as? ClassDefinition)?.isStatic != true,
                !typeDefinition.isValueType || SupportModules.WinRT.getBuiltInTypeKind(typeDefinition) != .definitionAndBinding {
            // Avoid toBindingTypeName because structs/enums have no -Binding suffix,
            // which would result in two files with the same name in the project, which SPM does not support.
            let fileName = "\(typeName)Binding.swift"
            try writeABIBindingConformanceFile(typeDefinition, module: module,
                toPath: "\(namespaceDirectoryPath)\\Bindings\\\(fileName)")
        }
    }

    if let cmakeOptions {
        let writer = CMakeListsWriter(output: FileTextOutputStream(
            path: "\(directoryPath)\\CMakeLists.txt",
            directoryCreation: .ancestors))
        writer.writeSingleLineCommand("file", "GLOB_RECURSE", "SOURCES", "*.swift")
        let targetName = cmakeOptions.getTargetName(moduleName: module.name)
        writer.writeSingleLineCommand(
            "add_library",
            .autoquote(targetName),
            .unquoted(cmakeOptions.dynamicLibraries ? "SHARED" : "STATIC"),
            .unquoted("${SOURCES}"))
        if targetName != module.name {
            writer.writeSingleLineCommand(
                "set_target_properties", .autoquote(targetName),
                "PROPERTIES", "Swift_MODULE_NAME", .autoquote(module.name))
        }
        writer.writeTargetLinkLibraries(targetName, .public,
            [ cmakeOptions.getTargetName(moduleName: module.abiModuleName), SupportModules.WinRT.moduleName ]
                + module.references.map { cmakeOptions.getTargetName(moduleName: $0.name) })
    }
}

fileprivate func writeNamespaceModuleFiles(_ module: Module, directoryPath: String, cmakeOptions: CMakeOptions?) throws {
    let typeDefinitionsByNamespace = Dictionary(grouping: module.typeDefinitions, by: { $0.namespace })

    var compactNamespaces: [String] = [] 
    for (namespace, typeDefinitions) in typeDefinitionsByNamespace {
        let typeDefinitions = try typeDefinitions.filter(hasSwiftDefinition)
        guard !typeDefinitions.isEmpty else { continue }
        guard let namespace else { continue }

        let compactNamespace = Projection.toCompactNamespace(namespace)
        compactNamespaces.append(compactNamespace)
        let namespaceAliasesPath = "\(directoryPath)\\\(compactNamespace)\\Aliases.swift"
        try writeNamespaceAliasesFile(typeDefinitions: typeDefinitions, module: module, toPath: namespaceAliasesPath)

        if let cmakeOptions {
            let writer = CMakeListsWriter(output: FileTextOutputStream(
                path: "\(directoryPath)\\\(compactNamespace)\\CMakeLists.txt",
                directoryCreation: .ancestors))
            let namespaceModuleName = module.getNamespaceModuleName(namespace: namespace)
            let targetName = cmakeOptions.getTargetName(moduleName: namespaceModuleName)
            writer.writeAddLibrary(targetName, .static, ["Aliases.swift"])
            if targetName != namespaceModuleName {
                writer.writeSingleLineCommand(
                    "set_target_properties", .unquoted(targetName),
                    "PROPERTIES", "Swift_MODULE_NAME", .unquoted(namespaceModuleName))
            }
            writer.writeTargetLinkLibraries(targetName, .public, [ cmakeOptions.getTargetName(moduleName: module.name) ])
        }
    }

    if cmakeOptions != nil, !compactNamespaces.isEmpty {
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

fileprivate func writeTypeDefinitionFile(_ typeDefinition: TypeDefinition, module: Module, toPath path: String) throws {
    let writer = SwiftSourceFileWriter(output: FileTextOutputStream(path: path, directoryCreation: .ancestors))
    writeGeneratedCodePreamble(to: writer)
    writeModulePreamble(module, to: writer)
    try writeTypeDefinition(typeDefinition, projection: module.projection, to: writer)
}

fileprivate func writeABIBindingConformanceFile(_ typeDefinition: TypeDefinition, module: Module, toPath path: String) throws {
    let writer = SwiftSourceFileWriter(output: FileTextOutputStream(path: path, directoryCreation: .ancestors))
    writeGeneratedCodePreamble(to: writer)
    writeModulePreamble(module, to: writer)

    if module.hasTypeDefinition(typeDefinition) {
        try writeABIBindingConformance(typeDefinition, genericArgs: nil, projection: module.projection, to: writer)
    }

    for genericArgs in module.genericInstantiationsByDefinition[typeDefinition] ?? [] {
        let boundType = typeDefinition.bindType(genericArgs: genericArgs)
        writer.writeMarkComment(try WinRTTypeName.from(type: boundType).description)
        try writeABIBindingConformance(typeDefinition, genericArgs: genericArgs, projection: module.projection, to: writer)
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

fileprivate func writeCOMInteropExtensionFile(typeDefinition: TypeDefinition, module: Module, toPath path: String) throws -> Bool {
    // IReference<T> is implemented generically in the support module.
    if typeDefinition.namespace == "Windows.Foundation", typeDefinition.name == "IReference`1" { return false }

    let instantiations = typeDefinition.genericArity == 0 ? [[]] : (module.genericInstantiationsByDefinition[typeDefinition] ?? [])
    guard !instantiations.isEmpty else { return false }

    let writer = SwiftSourceFileWriter(output: FileTextOutputStream(path: path, directoryCreation: .ancestors))
    writeGeneratedCodePreamble(to: writer)
    writeModulePreamble(module, to: writer)

    for genericArgs in instantiations {
        let boundType = typeDefinition.bindType(genericArgs: genericArgs)
        if instantiations.count > 1 {
            writer.writeMarkComment(try WinRTTypeName.from(type: boundType).description)
        }
        try writeCOMInteropExtension(abiType: boundType, projection: module.projection, to: writer)
    }

    return true
}

internal func writeNamespaceAliasesFile(typeDefinitions: [TypeDefinition], module: Module, toPath path: String) throws {
    let writer = SwiftSourceFileWriter(output: FileTextOutputStream(path: path, directoryCreation: .ancestors))
    writeGeneratedCodePreamble(to: writer)
    writer.writeImport(module: module.name)

    for typeDefinition in typeDefinitions.sorted(by: { $0.fullName < $1.fullName }) {
        guard typeDefinition.isPublic else { continue }

        try writeNamespaceAlias(typeDefinition, projection: module.projection, to: writer)
    }
}
