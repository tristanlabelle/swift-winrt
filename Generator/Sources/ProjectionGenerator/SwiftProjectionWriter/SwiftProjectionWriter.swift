import Collections
import CodeWriters
import DotNetMetadata

public struct SwiftProjectionWriter {
    internal let module: SwiftProjection.Module
    internal var projection: SwiftProjection { module.projection }

    public static func write(
            typeDefinition: TypeDefinition, closedGenericArgs: [TypeNode]? = nil,
            module: SwiftProjection.Module, toPath path: String) throws {
        let sourceFileWriter = SwiftSourceFileWriter(output: FileTextOutputStream(path: path))

        writeGeneratedCodePreamble(to: sourceFileWriter)

        sourceFileWriter.writeImport(module: module.projection.abiModuleName)
        sourceFileWriter.writeImport(module: "WindowsRuntime")

        for referencedModule in module.references {
            guard !referencedModule.isEmpty else { continue }
            sourceFileWriter.writeImport(module: referencedModule.name)
        }

        sourceFileWriter.writeImport(module: "Foundation", struct: "UUID")

        let hasGenericArgs = (closedGenericArgs?.count ?? 0) > 0

        let instance = SwiftProjectionWriter(module: module)
        switch typeDefinition {
            case let interfaceDefinition as InterfaceDefinition:
                if !hasGenericArgs { try instance.writeInterfaceDefinition(interfaceDefinition, to: sourceFileWriter) }
                try instance.writeInterfaceOrDelegateProjection(typeDefinition, genericArgs: closedGenericArgs, to: sourceFileWriter)

            case let delegateDefinition as DelegateDefinition:
                if !hasGenericArgs { try instance.writeDelegateDefinition(delegateDefinition, to: sourceFileWriter) }
                try instance.writeInterfaceOrDelegateProjection(typeDefinition, genericArgs: closedGenericArgs, to: sourceFileWriter)

            case let classDefinition as ClassDefinition:
                assert(!hasGenericArgs)
                try instance.writeClassDefinitionAndProjection(classDefinition, to: sourceFileWriter)

            case let structDefinition as StructDefinition:
                assert(!hasGenericArgs)
                try instance.writeStructDefinitionAndProjection(structDefinition, to: sourceFileWriter)

            case let enumDefinition as EnumDefinition:
                assert(!hasGenericArgs)
                try instance.writeEnumDefinitionAndProjection(enumDefinition, to: sourceFileWriter)

            default:
                assertionFailure("Unexpected TypeDefinition kind: \(typeDefinition.kind)")
        }
    }
}