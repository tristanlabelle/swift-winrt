import DotNetMetadata
import ProjectionGenerator
import Foundation

// Introduce a scope to workaround a compiler bug which allows
// global main.swift variables to be referred to before their initialization.
do {
    // Parse command line arguments
    let generateCommand = GenerateCommand.parseOrExit()

    // Resolve the mscorlib dependency from the .NET Framework 4 machine installation
    let context = AssemblyLoadContext()
    struct AssemblyLoadError: Error {}
    guard let mscorlibPath = SystemAssemblies.DotNetFramework4.mscorlibPath else { throw AssemblyLoadError() }
    _ = try context.load(path: mscorlibPath)

    let projection = try createProjection(generateCommand: generateCommand, assemblyLoadContext: context)
    try writeProjection(projection, generateCommand: generateCommand)
}
catch let error {
    print(error)
    fflush(stdout)
    throw error
}