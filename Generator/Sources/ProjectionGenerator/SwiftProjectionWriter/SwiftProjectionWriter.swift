import Collections
import CodeWriters
import DotNetMetadata

public struct SwiftProjectionWriter {
    internal let sourceFileWriter: SwiftSourceFileWriter
    internal let module: SwiftProjection.Module
    internal var projection: SwiftProjection { module.projection }

    public init(path: String, module: SwiftProjection.Module, importAbiModule: Bool) {
        self.sourceFileWriter = SwiftSourceFileWriter(output: FileTextOutputStream(path: path))
        self.module = module

        writeGeneratedCodePreamble(to: sourceFileWriter)

        if importAbiModule {
            sourceFileWriter.writeImport(module: projection.abiModuleName)
        }
        sourceFileWriter.writeImport(module: "WindowsRuntime")

        for referencedModule in module.references {
            guard !referencedModule.isEmpty else { continue }
            sourceFileWriter.writeImport(module: referencedModule.name)
        }

        sourceFileWriter.writeImport(module: "Foundation", struct: "UUID")
    }

    public func writeTypeDefinition(_ typeDefinition: TypeDefinition) throws {
        switch typeDefinition {
            case let interfaceDefinition as InterfaceDefinition:
                try writeInterface(interfaceDefinition)
            case let classDefinition as ClassDefinition:
                try writeClass(classDefinition)
            case let structDefinition as StructDefinition:
                try writeStruct(structDefinition)
            case let enumDefinition as EnumDefinition:
                try writeEnum(enumDefinition)
            case let delegateDefinition as DelegateDefinition:
                try writeDelegate(delegateDefinition)
            default:
                assertionFailure("Unexpected TypeDefinition kind: \(typeDefinition.kind)")
        }
    }

    public func writeBuiltInExtensions(_ typeDefinition: TypeDefinition) throws {
        if typeDefinition.namespace == "Windows.Foundation" {
            let typeName: String
            if let interfaceDefinition = typeDefinition as? InterfaceDefinition {
                typeName = try module.projection.toProtocolName(interfaceDefinition)
            } else {
                typeName = try module.projection.toTypeName(typeDefinition)
            }

            switch typeDefinition.name {
                case "DateTime":
                    try writeDateTimeExtensions(typeName: typeName)
                case "TimeSpan":
                    try writeTimeSpanExtensions(typeName: typeName)
                case "IAsyncAction", "IAsyncActionWithProgress`1":
                    try writeIAsyncExtensions(protocolName: typeName, resultType: nil)
                case "IAsyncOperation`1", "IAsyncOperationWithProgress`2":
                    try writeIAsyncExtensions(
                        protocolName: typeName,
                        resultType: .identifier(name: String(typeDefinition.genericParams[0].name)))
                default: break
            }
        }
    }

    public func writeProjection(_ typeDefinition: TypeDefinition, genericArgs: [TypeNode]? = nil) throws {
        let hasGenericArgs = (genericArgs?.count ?? 0) > 0
        switch typeDefinition {
            case is InterfaceDefinition:
                try writeInterfaceOrDelegateProjection(typeDefinition, genericArgs: genericArgs)

            case let classDefinition as ClassDefinition:
                assert(!hasGenericArgs)
                try writeClassProjection(classDefinition)

            case let enumDefinition as EnumDefinition:
                assert(!hasGenericArgs)
                try writeEnumProjection(enumDefinition)

            case let structDefinition as StructDefinition:
                assert(!hasGenericArgs)
                try writeStructProjection(structDefinition)

            case is DelegateDefinition:
                try writeInterfaceOrDelegateProjection(typeDefinition, genericArgs: genericArgs)

            default: fatalError("Unexpected type definition kind")
        }
    }
}