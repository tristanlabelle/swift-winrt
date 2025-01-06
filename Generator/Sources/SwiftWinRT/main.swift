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

    let spmOptions = SPMOptions(commandLineArguments: commandLineArguments, projectionConfig: projectionConfig)
    let cmakeOptions = CMakeOptions(commandLineArguments: commandLineArguments, projectionConfig: projectionConfig)

    let context = WinMDLoadContext()
    _ = try context.load(path: commandLineArguments.mscorlibPath ?? getDefaultMscorlibPath())

    let projection = try createProjection(
        commandLineArguments: commandLineArguments,
        projectionConfig: projectionConfig,
        winMDLoadContext: context)

    try writeProjectionFiles(projection,
        swiftBug72724: commandLineArguments.swiftBug72724.asBool,
        cmakeOptions: cmakeOptions,
        directoryPath: commandLineArguments.outputDirectoryPath)

    if let spmOptions {
        writeSwiftPackageFile(projection, spmOptions: spmOptions,
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

func getDefaultMscorlibPath() -> String {
    Bundle.main.executableURL!
        .deletingLastPathComponent()
        .appendingPathComponent("mscorlib.winmd", isDirectory: false)
        .path
        .replacingOccurrences(of: "/", with: "\\")
}