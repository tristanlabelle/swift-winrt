import DotNetMetadata
import ProjectionModel
import Foundation
import WindowsMetadata

// Introduce a scope to workaround a compiler bug which allows
// global main.swift variables to be referred to before their initialization.
do {
    // Parse command line arguments
    let commandLineArguments = CommandLineArguments.parseOrExit()

    // Load the projection config file, if any
    let projectionConfig: ProjectionConfig
    if let configFilePath = commandLineArguments.configFilePath {
        let jsonData = try Data(contentsOf: URL(fileURLWithPath: configFilePath))
        projectionConfig = try JSONDecoder().decode(ProjectionConfig.self, from: jsonData)
    }
    else {
        projectionConfig = ProjectionConfig()
    }

    // Resolve the mscorlib dependency from the .NET Framework 4 machine installation
    let context = WinMDLoadContext()
    guard let mscorlibPath = SystemAssemblies.DotNetFramework4.mscorlibPath else {
        throw AssemblyLoadError.notFound(message: "mscorlib was not found on the machine.")
    }
    _ = try context.load(path: mscorlibPath)

    let projection = try createProjection(
        commandLineArguments: commandLineArguments,
        projectionConfig: projectionConfig,
        winMDLoadContext: context)

    try writeProjectionFiles(projection,
        swiftBug72724: commandLineArguments.swiftBug72724.asBool,
        cmakeOptions: !commandLineArguments.generateCMakeLists ? nil : CMakeOptions(
            targetPrefix: commandLineArguments.cmakeTargetPrefix,
            targetSuffix: commandLineArguments.cmakeTargetSuffix,
            dynamicLibraries: commandLineArguments.dynamicLibraries),
        directoryPath: commandLineArguments.outputDirectoryPath)

    if commandLineArguments.generatePackageDotSwift {
        writeSwiftPackageFile(
            projection,
            spmOptions: SPMOptions(
                supportPackageReference: commandLineArguments.spmSupportPackageReference,
                libraryPrefix: commandLineArguments.spmLibraryPrefix,
                librarySuffix: commandLineArguments.spmLibrarySuffix,
                dynamicLibraries: commandLineArguments.dynamicLibraries,
                excludeCMakeLists: commandLineArguments.generateCMakeLists),
            toPath: "\(commandLineArguments.outputDirectoryPath)\\Package.swift")
    }

    if let exeManifestPath = commandLineArguments.exeManifestPath {
        try writeExeManifestFile(projectionConfig: projectionConfig, projection: projection, toPath: exeManifestPath)
    }
}
catch let error {
    print(error)
    fflush(stdout)
    throw error
}