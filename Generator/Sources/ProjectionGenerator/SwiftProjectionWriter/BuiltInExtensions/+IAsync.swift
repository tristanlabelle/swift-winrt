import CodeWriters

extension SwiftProjectionWriter {
    internal func writeIAsyncExtensions(protocolName: String, resultType: SwiftType?) throws {
        sourceFileWriter.writeExtension(name: protocolName) { writer in
            // public get() async throws
            writer.writeFunc(visibility: .public, name: "get", async: true, throws: true, returnType: resultType) { writer in
                writer.output.writeIndentedBlock(header: "if try status == .started {", footer: "}") {
                    // We can't await if the completed handler is already set
                    writer.writeStatement("guard try COM.NullResult.catch(completed) == nil else { throw COM.HResult.Error.illegalMethodCall }")
                    writer.writeStatement("let awaiter = WindowsRuntime.AsyncAwaiter()")
                    writer.writeStatement("try completed({ _, _ in _Concurrency.Task { await awaiter.signal() } })")
                    writer.writeStatement("await awaiter.wait()")
                }

                // Handles exceptions and cancelation
                writer.writeStatement("return try getResults()")
            }
        }
    }
}