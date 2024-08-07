import DotNetMetadata
import ProjectionModel
import Foundation

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
    let context = AssemblyLoadContext()
    struct AssemblyLoadError: Error {}
    guard let mscorlibPath = SystemAssemblies.DotNetFramework4.mscorlibPath else { throw AssemblyLoadError() }
    _ = try context.load(path: mscorlibPath)

    let projection = try createProjection(
        commandLineArguments: commandLineArguments,
        projectionConfig: projectionConfig,
        assemblyLoadContext: context)
    try writeProjectionFiles(projection, commandLineArguments: commandLineArguments)

    if commandLineArguments.generatePackageDotSwift {
        writeSwiftPackageFile(
            projection,
            supportPackageLocation: commandLineArguments.supportPackageLocation,
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