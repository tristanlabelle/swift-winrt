import DotNetMetadata
import ProjectionGenerator

// Parse command line arguments
let generateCommand = GenerateCommand.parseOrExit()

// Resolve the mscorlib dependency from the .NET Framework 4 machine installation
let context = AssemblyLoadContext()
struct AssemblyLoadError: Error {}
guard let mscorlibPath = SystemAssemblies.DotNetFramework4.mscorlibPath else { throw AssemblyLoadError() }
_ = try context.load(path: mscorlibPath)

let projection = try createProjection(generateCommand: generateCommand, assemblyLoadContext: context)
try writeProjection(projection, generateCommand: generateCommand)