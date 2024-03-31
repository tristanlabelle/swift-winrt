import CodeWriters
import DotNetMetadata
import WindowsMetadata
import ProjectionModel

internal func writeInterfaceExtensions(_ interface: InterfaceDefinition, projection: SwiftProjection, to writer: SwiftSourceFileWriter) throws {
    switch interface.namespace {
        case "Windows.Foundation":
            let typeName = try projection.toProtocolName(interface)
            switch interface.name {
                case "IAsyncAction", "IAsyncActionWithProgress`1":
                    try writeIAsyncExtensions(protocolName: typeName, resultType: nil, to: writer)
                case "IAsyncOperation`1", "IAsyncOperationWithProgress`2":
                    try writeIAsyncExtensions(
                        protocolName: typeName,
                        resultType: .identifier(name: String(interface.genericParams[0].name)),
                        to: writer)
                default: break
            }
        default: break
    }
}

internal func writeIAsyncExtensions(protocolName: String, resultType: SwiftType?, to writer: SwiftSourceFileWriter) throws {
    writer.writeExtension(type: .identifier(protocolName)) { writer in
        // public get() async throws
        writer.writeFunc(visibility: .public, name: "get", async: true, throws: true, returnType: resultType) { writer in
            writer.output.writeIndentedBlock(header: "if try _status() == .started {", footer: "}") {
                // We can't await if the completed handler is already set
                writer.writeStatement("guard try \(SupportModules.COM.nullResult).catch(_completed()) == nil else { throw \(SupportModules.COM.hresult).Error.illegalMethodCall }")
                writer.writeStatement("let awaiter = WindowsRuntime.AsyncAwaiter()")
                writer.writeStatement("try _completed({ _, _ in _Concurrency.Task { await awaiter.signal() } })")
                writer.writeStatement("await awaiter.wait()")
            }

            // Handles exceptions and cancelation
            writer.writeStatement("return try getResults()")
        }
    }
}
