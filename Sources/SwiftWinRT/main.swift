import DotNetMD
import Foundation

let namespace = CommandLine.arguments.dropFirst().first ?? "Windows.Foundation"

let context = MetadataContext()
let assembly = try context.loadAssembly(path: #"C:\Program Files (x86)\Windows Kits\10\UnionMetadata\10.0.22000.0\Windows.winmd"#)

public struct StdoutOutputStream: TextOutputStream {
    public mutating func write(_ str: String) { fputs(str, stdout) }
}

//writeProjectionSourceFile(assembly: assembly, namespace: namespace, to: StdoutOutputStream())

let cabiWriter = CAbi.SourceFileWriter(output: StdoutOutputStream())

for typeDefinition in assembly.definedTypes {
    guard typeDefinition.namespace == namespace,
        typeDefinition.visibility == .public,
        typeDefinition.genericParams.isEmpty else { continue }

    if let structDefinition = typeDefinition as? StructDefinition {
        try? cabiWriter.writeStruct(structDefinition)
    }
    else if let enumDefinition = typeDefinition as? EnumDefinition {
        try? cabiWriter.writeEnum(enumDefinition)
    }
    else if let interfaceDefinition = typeDefinition as? InterfaceDefinition {
        try? cabiWriter.writeInterface(interfaceDefinition, genericArgs: [])
    }
}