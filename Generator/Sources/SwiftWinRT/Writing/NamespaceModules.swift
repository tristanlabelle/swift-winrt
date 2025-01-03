import CodeWriters
import DotNetMetadata
import ProjectionModel

/// Writes a namespace module to a given directory.
/// A namespace module contains short name typealiases for all types in the projection module,
/// for example "public typealias MyType = MainModule.MyNamespace_MyType".
internal func writeNamespaceModule(module: Module, namespace: String, typeDefinitions: [TypeDefinition], cmakeOptions: CMakeOptions?, directoryPath: String) throws {
    let writer = SwiftSourceFileWriter(
        output: FileTextOutputStream(path: "\(directoryPath)\\Aliases.swift", directoryCreation: .ancestors))
    writeGeneratedCodePreamble(to: writer)
    writer.writeImport(module: module.name)

    for typeDefinition in typeDefinitions.sorted(by: { $0.fullName < $1.fullName }) {
        try writeShortNameTypeAlias(typeDefinition, projection: module.projection, to: writer)
    }

    if let cmakeOptions {
        let writer = CMakeListsWriter(output: FileTextOutputStream(
            path: "\(directoryPath)\\CMakeLists.txt",
            directoryCreation: .ancestors))

        let targetName = cmakeOptions.getTargetName(moduleName: module.name) + module.getNamespaceModuleSuffix(namespace: namespace)
        let moduleName = module.name + module.getNamespaceModuleSuffix(namespace: namespace)
        writer.writeAddLibrary(targetName, .static, ["Aliases.swift"])
        if targetName != moduleName {
            writer.writeSingleLineCommand(
                "set_target_properties", .autoquote(targetName),
                "PROPERTIES", "Swift_MODULE_NAME", .autoquote(moduleName))
        }

        writer.writeTargetLinkLibraries(targetName, .public, [ cmakeOptions.getTargetName(moduleName: module.name) ])
    }
}

/// Writes the flat namespace module to a given directory.
/// The flat namespace reexports the types from all namespace modules,
/// provided unqualified name access to all types in the projection module.
internal func writeFlatNamespaceModule(module: Module, namespaces: [String], cmakeOptions: CMakeOptions?, directoryPath: String) throws {
    let writer = SwiftSourceFileWriter(
        output: FileTextOutputStream(path: "\(directoryPath)\\Flat.swift", directoryCreation: .ancestors))
    writeGeneratedCodePreamble(to: writer)

    for namespace in namespaces {
        writer.writeImport(exported: true, module: module.getNamespaceModuleName(namespace: namespace))
    }

    if let cmakeOptions {
        let writer = CMakeListsWriter(output: FileTextOutputStream(
            path: "\(directoryPath)\\CMakeLists.txt",
            directoryCreation: .ancestors))

        let flatModuleName = module.name + Module.flatModuleSuffix
        let targetName = cmakeOptions.getTargetName(moduleName: module.name) + Module.flatModuleSuffix
        writer.writeAddLibrary(targetName, .static, ["Flat.swift"])
        if targetName != flatModuleName {
            writer.writeSingleLineCommand(
                "set_target_properties", .autoquote(targetName),
                "PROPERTIES", "Swift_MODULE_NAME", .autoquote(flatModuleName))
        }

        let namespaceModuleTargetNames = namespaces.map {
            cmakeOptions.getTargetName(moduleName: module.name) + module.getNamespaceModuleSuffix(namespace: $0)
        }
        writer.writeTargetLinkLibraries(targetName, .public,
            // Workaround CMake bug that doesn't always transitively inherit link libraries.
            [ cmakeOptions.getTargetName(moduleName: module.name) ] + namespaceModuleTargetNames)
    }
}

/// Writes a typealias exposing a type from the projection module by its short name.
/// For example, "public typealias MyType = MainModule.MyNamespace_MyType".
fileprivate func writeShortNameTypeAlias(
        _ typeDefinition: TypeDefinition,
        projection: Projection,
        to writer: SwiftSourceFileWriter) throws {
    try writer.writeTypeAlias(
        visibility: Projection.toVisibility(typeDefinition.visibility),
        name: projection.toTypeName(typeDefinition, namespaced: false),
        typeParams: typeDefinition.genericParams.map { $0.name },
        target: .named(
            projection.toTypeName(typeDefinition),
            genericArgs: typeDefinition.genericParams.map { .named($0.name) }))

    if let interface = typeDefinition as? InterfaceDefinition {
        // We can't typealias protocols, so we define a new one that inherits from the original.
        // Compare `IFooProtocol` with `MyNamespace_IFooProtocol`:
        // - When implementing `IFooProtocol`, we are implementing `MyNamespace_IFooProtocol`, so that works.
        // - When using `any IFooProtocol`, we are using an incompatible type from `any MyNamespace_IFooProtocol`,
        //   however, the code should be using `IFoo`, which avoids this issue.
        try writer.writeProtocol(
            visibility: Projection.toVisibility(interface.visibility),
            name: projection.toProtocolName(interface, namespaced: false),
            typeParams: interface.genericParams.map { $0.name },
            bases: [projection.toBaseProtocol(interface)]) { _ in }
    }

    if typeDefinition is InterfaceDefinition || typeDefinition is DelegateDefinition {
        try writer.writeTypeAlias(
            visibility: Projection.toVisibility(typeDefinition.visibility),
            name: projection.toBindingTypeName(typeDefinition, namespaced: false),
            target: projection.toBindingType(typeDefinition))
    }
}