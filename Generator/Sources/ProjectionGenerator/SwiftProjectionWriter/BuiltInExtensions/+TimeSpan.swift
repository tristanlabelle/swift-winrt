extension SwiftProjectionWriter {
    internal func writeTimeSpanExtensions(typeName: String) throws {
        sourceFileWriter.writeImport(module: "Foundation", struct: "TimeInterval")

        sourceFileWriter.writeExtension(name: typeName) { writer in
            // public init(timeInterval: TimeInterval)
            writer.writeInit(visibility: .public,
                    params: [.init(name: "timeInterval", type: .chain("Foundation", "TimeInterval"))]) { writer in
                writer.writeStatement("self.init(duration: Int64(timeInterval * 10_000_000))")
            }

            // public var timeInterval: TimeInterval
            writer.writeComputedProperty(visibility: .public, name: "timeInterval", type: .chain("Foundation", "TimeInterval"),
                get: { writer in
                    writer.writeStatement("Double(duration) / 10_000_000")
                },
                set: { writer in
                    writer.writeStatement("self = Self(timeInterval: newValue)")
                })
        }
    }
}