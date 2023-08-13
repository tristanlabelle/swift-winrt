import CodeWriters
import DotNetMetadata
import Foundation
import ArgumentParser

@main
struct EntryPoint: ParsableCommand {
    @Option(name: .customLong("reference"), help: "A path to a .winmd file with the APIs to project.")
    var references: [String] = []

    @Option(help: "A Windows SDK version with the APIs to project.")
    var sdk: String? = nil

    @Option(name: .customLong("module-map"), help: "A path to a module map json file to use.")
    var moduleMap: String? = nil

    @Option(help: "A path to the output directory.")
    var out: String

    mutating func run() throws {
        var allReferences = Set(references)
        if let sdk {
            allReferences.insert("C:\\Program Files (x86)\\Windows Kits\\10\\UnionMetadata\\\(sdk)\\Windows.winmd")
        }

        let moduleMap: ModuleMapFile?
        if let moduleMapPath = self.moduleMap {
            moduleMap = try JSONDecoder().decode(ModuleMapFile.self, from: Data(contentsOf: URL(fileURLWithPath: moduleMapPath)))
        }
        else {
            moduleMap = nil
        }

        let context = MetadataContext()
        let swiftProjection = SwiftProjection()
        var typeGraphWalker = TypeGraphWalker(publicMembersOnly: true)

        // Gather types from all referenced assemblies
        for reference in allReferences {
            let assembly = try context.loadAssembly(path: reference)

            let (moduleName, moduleMapping) = Self.getModule(assemblyName: assembly.name, moduleMapFile: moduleMap)
            let module = swiftProjection.modulesByName[moduleName] ?? swiftProjection.addModule(moduleName)
            module.addAssembly(assembly)

            for typeDefinition in assembly.definedTypes {
                if typeDefinition.visibility == .public && Self.isIncluded(fullName: typeDefinition.fullName, filters: moduleMapping?.includeFilters) {
                    typeGraphWalker.walk(typeDefinition)
                }
            }
        }

        // Classify types into modules
        for typeDefinition in typeGraphWalker.definitions {
            let module: SwiftProjection.Module
            if let existingModule = swiftProjection.assembliesToModules[typeDefinition.assembly] {
                module = existingModule
            }
            else {
                let (moduleName, _) = Self.getModule(assemblyName: typeDefinition.assembly.name, moduleMapFile: moduleMap)
                module = swiftProjection.addModule(moduleName)
                module.addAssembly(typeDefinition.assembly)
            }

            module.addType(typeDefinition)
        }

        // Establish references between modules
        for assembly in context.loadedAssemblies {
            guard !(assembly is Mscorlib) else { continue }

            if let sourceModule = swiftProjection.assembliesToModules[assembly] {
                for reference in assembly.references {
                    if let targetModule = swiftProjection.assembliesToModules[try reference.resolve()] {
                        sourceModule.addReference(targetModule)
                    }
                }
            }
        }

        for module in swiftProjection.modulesByName.values {
            let outputDirectoryPath = "\(out)\\\(module.name)"
            try FileManager.default.createDirectory(atPath: outputDirectoryPath, withIntermediateDirectories: true)
            swiftProjection.writeModule(module, outputDirectoryPath: outputDirectoryPath)
        }
    }

    static func getModule(assemblyName: String, moduleMapFile: ModuleMapFile?) -> (name: String, mapping: ModuleMapFile.Module?) {
        if let moduleMapFile {
            for (moduleName, module) in moduleMapFile.modules {
                if module.assemblies.contains(assemblyName) {
                    return (moduleName, module)
                }
            }
        }

        return (assemblyName, nil)
    }

    static func isIncluded(fullName: String, filters: [String]?) -> Bool {
        guard let filters else { return true }

        for filter in filters {
            if filter.last == "*" {
                if fullName.starts(with: filter.dropLast()) {
                    return true
                }
            }
            else if fullName == filter {
                return true
            }
        }

        return false
    }
}

// let cabiWriter = CAbi.SourceFileWriter(output: StdoutOutputStream())

// for typeDefinition in assembly.definedTypes {
//     guard typeDefinition.namespace == namespace,
//         typeDefinition.visibility == .public,
//         typeDefinition.genericParams.isEmpty else { continue }

//     if let structDefinition = typeDefinition as? StructDefinition {
//         try? cabiWriter.writeStruct(structDefinition)
//     }
//     else if let enumDefinition = typeDefinition as? EnumDefinition {
//         try? cabiWriter.writeEnum(enumDefinition)
//     }
//     else if let interfaceDefinition = typeDefinition as? InterfaceDefinition {
//         try? cabiWriter.writeInterface(interfaceDefinition, genericArgs: [])
//     }
// }