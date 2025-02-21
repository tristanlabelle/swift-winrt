import CodeWriters
import Collections
import DotNetMetadata
import DotNetXMLDocs
import Foundation
import ProjectionModel
import WindowsMetadata

internal func writeProjectionFiles(
        _ projection: Projection,
        swiftBug72724: Bool?,
        cmakeOptions: CMakeOptions?,
        directoryPath: String) throws {
    for module in projection.modulesByName.values {
        guard !module.isEmpty else { continue }
        print("Generating projection for \(module.name)...")
        try writeModuleFiles(module,
            swiftBug72724: swiftBug72724,
            cmakeOptions: cmakeOptions,
            directoryPath: "\(directoryPath)\\\(module.name)")
    }

    if cmakeOptions != nil {
        let writer = CMakeListsWriter(output: FileTextOutputStream(
            path: "\(directoryPath)\\CMakeLists.txt",
            directoryCreation: .ancestors))

        // Workaround for https://github.com/swiftlang/swift-driver/issues/1477
        // The threshold value has to be real high because the driver multiplies the number of input files by ~50.
        // See https://github.com/swiftlang/swift-driver/blob/6af4c7dbc0559694578e5221d49970f94603b9e5/Sources/SwiftDriver/Jobs/FrontendJobHelpers.swift#L714
        writer.writeSingleLineCommand("add_compile_options", .unquoted("-driver-filelist-threshold=\(Int32.max)"))

        for module in projection.modulesByName.values.sorted(by: { $0.name < $1.name }) {
            guard !module.isEmpty else { continue }
            writer.writeAddSubdirectory(module.name)
        }
    }
}

fileprivate func writeModuleFiles(
        _ module: Module,
        swiftBug72724: Bool?,
        cmakeOptions: CMakeOptions?,
        directoryPath: String) throws {
    try writeABIModule(module, cmakeOptions: cmakeOptions, directoryPath: "\(directoryPath)\\ABI")

    try writeSwiftModuleFiles(module,
        swiftBug72724: swiftBug72724, cmakeOptions: cmakeOptions,
        directoryPath: "\(directoryPath)\\Projection")

    try writeNamespaceModules(module, cmakeOptions: cmakeOptions, directoryPath: "\(directoryPath)\\Namespaces")

    if cmakeOptions != nil {
        let writer = CMakeListsWriter(output: FileTextOutputStream(
            path: "\(directoryPath)\\CMakeLists.txt",
            directoryCreation: .ancestors))
        writer.writeAddSubdirectory("ABI")
        writer.writeAddSubdirectory("Projection")
        writer.writeAddSubdirectory("Namespaces")
    }
}

fileprivate func writeSwiftModuleFiles(
        _ module: Module,
        swiftBug72724: Bool?,
        cmakeOptions: CMakeOptions?,
        directoryPath: String) throws {
    // We lazily create a single COMInterop extensions file per module.
    // Previously, we created one per type, but the Swift compiler runs into issues with large number of files.
    // See https://github.com/swiftlang/swift/issues/76994
    var comInteropFileWriter: SwiftSourceFileWriter! = nil

    for (compactNamespace, typeDefinitions) in module.getTypeDefinitionsByCompactNamespace(includeGenericInstantiations: true) {
        for typeDefinition in typeDefinitions {
            let namespaceDirectoryPath = "\(directoryPath)\\\(compactNamespace)"
            let typeName = try module.projection.toTypeName(typeDefinition)

            // Write the COM interop extensions
            let comInteropableTypes = try getCOMInteropableTypes(typeDefinition: typeDefinition, module: module)
            if !comInteropableTypes.isEmpty {
                // Lazy initialize the COM interop file writer
                if comInteropFileWriter == nil {
                    let filePath = "\(directoryPath)\\COMInterop+Extensions.swift"
                    comInteropFileWriter = SwiftSourceFileWriter(
                        output: FileTextOutputStream(path: filePath, directoryCreation: .ancestors))
                    writeGeneratedCodePreamble(to: comInteropFileWriter)
                    writeModulePreamble(module, to: comInteropFileWriter)
                }

                for comInteropableType in comInteropableTypes {
                    comInteropFileWriter.writeMarkComment(try WinRTTypeName.from(type: comInteropableType).description)
                    try writeCOMInteropExtension(abiType: comInteropableType, projection: module.projection, to: comInteropFileWriter)
                }
            }

            // Write the type definition and binding type
            guard try hasSwiftDefinition(typeDefinition) else { continue }

            if module.hasTypeDefinition(typeDefinition) {
                try writeTypeDefinitionFile(
                    typeDefinition,
                    module: module,
                    swiftBug72724: swiftBug72724,
                    toPath: "\(namespaceDirectoryPath)\\\(typeName).swift")

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

        // Workaround for https://github.com/swiftlang/swift-driver/issues/1477
        // The threshold value has to be real high because the driver multiplies the number of input files by ~50.
        // See https://github.com/swiftlang/swift-driver/blob/6af4c7dbc0559694578e5221d49970f94603b9e5/Sources/SwiftDriver/Jobs/FrontendJobHelpers.swift#L714
        writer.writeSingleLineCommand(
            "target_compile_options", .autoquote(targetName),
            "PRIVATE", .unquoted("-driver-filelist-threshold=\(Int32.max)"))

        var linkLibraries: [String] = [
            cmakeOptions.getTargetName(moduleName: module.name) + Module.abiModuleSuffix,
            SupportModules.WinRT.moduleName
        ]
        for reference in module.references {
            guard !reference.isEmpty else { continue }
            linkLibraries.append(cmakeOptions.getTargetName(moduleName: reference.name))
        }
        writer.writeTargetLinkLibraries(targetName, .public, linkLibraries)
    }
}

/// Writes the directory structure containing namespace modules for a given module.
///
/// The structure looks like:
///
/// ```
/// <root module directory>
/// └── Namespaces
///     ├── WindowsFoundation
///     │   ├── Aliases.swift
///     │   └── CMakeLists.txt
///     ├── Flat
///     │   ├── Flat.swift
///     │   └── CMakeLists.txt
///     └── CMakeLists.txt
/// ```
fileprivate func writeNamespaceModules(
        _ module: Module,
        cmakeOptions: CMakeOptions?,
        directoryPath: String) throws {
    let typeDefinitionsByNamespace = Dictionary(grouping: module.typeDefinitions, by: { $0.namespace })

    var compactNamespaces: [String] = [] 
    for (namespace, typeDefinitions) in typeDefinitionsByNamespace {
        let typeDefinitions = try typeDefinitions.filter(hasSwiftDefinition)
        guard !typeDefinitions.isEmpty else { continue }
        guard let namespace else { continue }

        let compactNamespace = Projection.toCompactNamespace(namespace)
        try writeNamespaceModule(
            module: module,
            namespace: namespace,
            typeDefinitions: typeDefinitions,
            cmakeOptions: cmakeOptions,
            directoryPath: "\(directoryPath)\\\(compactNamespace)")

        compactNamespaces.append(compactNamespace)
    }

    guard !compactNamespaces.isEmpty else { return }

    compactNamespaces.sort()

    try writeFlatNamespaceModule(
        module: module,
        namespaces: compactNamespaces,
        cmakeOptions: cmakeOptions,
        directoryPath: "\(directoryPath)\\Flat")

    if cmakeOptions != nil {
        let writer = CMakeListsWriter(output: FileTextOutputStream(
            path: "\(directoryPath)\\CMakeLists.txt",
            directoryCreation: .ancestors))
        for compactNamespace in compactNamespaces {
            writer.writeAddSubdirectory(compactNamespace)
        }
        writer.writeAddSubdirectory("Flat")
    }
}

fileprivate func hasSwiftDefinition(_ typeDefinition: TypeDefinition) throws -> Bool {
    return try SupportModules.WinRT.getBuiltInTypeKind(typeDefinition) != .special
        && !typeDefinition.hasAttribute(ApiContractAttribute.self)
        && typeDefinition.isPublic
}

fileprivate func writeTypeDefinitionFile(
        _ typeDefinition: TypeDefinition,
        module: Module,
        swiftBug72724: Bool?,
        toPath path: String) throws {
    let writer = SwiftSourceFileWriter(output: FileTextOutputStream(path: path, directoryCreation: .ancestors))
    writeGeneratedCodePreamble(to: writer)
    writeModulePreamble(module, to: writer)
    try writeTypeDefinition(
        typeDefinition,
        projection: module.projection,
        swiftBug72724: swiftBug72724,
        to: writer)
}

fileprivate func writeABIBindingConformanceFile(_ typeDefinition: TypeDefinition, module: Module, toPath path: String) throws {
    let bindingDefinedInSupportModule = SupportModules.WinRT.getBuiltInTypeKind(typeDefinition) == .definitionAndBinding
    if bindingDefinedInSupportModule { 
        if !module.hasTypeDefinition(typeDefinition) {
            // This is a generic instantiation of a type that is defined in the support module.
            // Since the support module defines the binding, it must be defined in a way that
            // covers all generic instantiations, e.g. WindowsFoundation_IReferenceBinding.
            return
        }
        if typeDefinition.isValueType {
            // We're generating the module for WindowsFoundation and this type is a value type,
            // like WindowsFoundation_Point. We're reexporting the type from the support module
            // elsewhere, and it implements ABIBinding itself, so we don't need to generate it again.
            return
        }
    }

    let writer = SwiftSourceFileWriter(output: FileTextOutputStream(path: path, directoryCreation: .ancestors))
    writeGeneratedCodePreamble(to: writer)
    writeModulePreamble(module, to: writer)

    if module.hasTypeDefinition(typeDefinition) {
        if bindingDefinedInSupportModule {
            // We're generating the module for WindowsFoundation and this type's binding is defined in the support module,
            // like WindowsFoundation_IStringableBinding. Just reexport the binding here.
            writer.writeImport(exported: true, kind: .enum,
                module: SupportModules.WinRT.moduleName,
                symbolName: try module.projection.toBindingTypeName(typeDefinition))
            return
        }

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

fileprivate func getCOMInteropableTypes(typeDefinition: TypeDefinition, module: Module) throws -> [BoundType] {
    guard typeDefinition.kind == .interface || typeDefinition.kind == .delegate else { return [] }
    // IReference<T> is implemented generically in the support module.
    if typeDefinition.namespace == "Windows.Foundation", typeDefinition.name == "IReference`1" { return [] }
    return module.getTypeInstantiations(definition: typeDefinition)
}
