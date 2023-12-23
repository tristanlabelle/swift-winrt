extension SwiftProjectionWriter {
    internal func writeDateTimeExtensions(typeName: String) throws {
        sourceFileWriter.writeImport(module: "Foundation", struct: "Date")

        sourceFileWriter.writeExtension(name: typeName) { writer in
            // public init(foundationDate: Date)
            writer.writeInit(visibility: .public,
                    params: [.init(name: "foundationDate", type: .chain("Foundation", "Date"))]) { writer in
                // TimeInterval has limited precision to work with (it is a Double), so explicitly work at millisecond precision
                writer.writeStatement("self.init(universalTime: (Int64(foundationDate.timeIntervalSince1970 * 1000) + 11_644_473_600_000) * 10_000)")
            }

            // public var foundationDate: Date
            writer.writeComputedProperty(visibility: .public, name: "foundationDate", type: .chain("Foundation", "Date"),
                get: { writer in
                    // TimeInterval has limited precision to work with (it is a Double), so explicitly work at millisecond precision
                    writer.writeStatement("Date(timeIntervalSince1970: Double(universalTime / 10_000) / 1000 - 11_644_473_600)")
                },
                set: { writer in
                    writer.writeStatement("self = Self(foundationDate: newValue)")
                })
        }
    }
}