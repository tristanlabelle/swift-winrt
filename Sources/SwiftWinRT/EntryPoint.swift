import DotNetMD
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

        for reference in allReferences {
            let assembly = try context.loadAssembly(path: reference)

            let (moduleName, includeFilters) = Self.getModuleNameAndIncludeFilters(assemblyName: assembly.name, moduleMapFile: moduleMap)

            var typeGraphWalker = TypeGraphWalker(publicMembersOnly: true)
            for typeDefinition in assembly.definedTypes {
                if typeDefinition.visibility == .public && Self.isIncluded(fullName: typeDefinition.fullName, filters: includeFilters) {
                    typeGraphWalker.walk(typeDefinition)
                }
            }

            let outputDirectoryPath = "\(out)\\\(moduleName)"
            try FileManager.default.createDirectory(atPath: outputDirectoryPath, withIntermediateDirectories: true)

            SwiftProjection.writeSourceFile(
                assembly: assembly,
                filter: { typeGraphWalker.definitions.contains($0) },
                to: FileTextOutputStream(path: "\(outputDirectoryPath)\\\(assembly.name).swift"))
        }
    }

    static func getModuleNameAndIncludeFilters(assemblyName: String, moduleMapFile: ModuleMapFile?) -> (moduleName: String, includeFilters: [String]?) {
        if let moduleMapFile {
            for (moduleName, module) in moduleMapFile.modules {
                if module.assemblies.contains(assemblyName) {
                    return (moduleName, module.includeFilters)
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

    class FileTextOutputStream: TextOutputStream {
        let path: String
        var text: String = String()

        init(path: String) {
            self.path = path
        }

        func write(_ string: String) {
            text.write(string)
        }

        deinit {
            try? text.write(toFile: path, atomically: true, encoding: .utf8)
        }
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