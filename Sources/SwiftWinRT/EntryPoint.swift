import DotNetMD
import Foundation
import ArgumentParser

@main
struct EntryPoint: ParsableCommand {
    @Option(help: "A path to the .winmd file to parse.")
    var winmd: String = #"C:\Program Files (x86)\Windows Kits\10\UnionMetadata\10.0.22000.0\Windows.winmd"#

    @Option(help: "The namespace for which to generate bindings.")
    var namespace: String = "Windows.Foundation"

    mutating func run() throws {
        let context = MetadataContext()
        let assembly = try context.loadAssembly(path: #"C:\Program Files (x86)\Windows Kits\10\UnionMetadata\10.0.22000.0\Windows.winmd"#)

        struct StdoutOutputStream: TextOutputStream {
            public mutating func write(_ str: String) { fputs(str, stdout) }
        }

        writeProjectionSourceFile(assembly: assembly, namespace: namespace, to: StdoutOutputStream())
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