public final class CMakeListsWriter {
    public let output: LineBasedTextOutputStream

    public init(output: some TextOutputStream) {
        self.output = .init(inner: output)
    }

    public func writeCommand(
            lineGroup: LineBasedTextOutputStream.LineGroup? = nil,
            _ command: String,
            headerArguments: [CMakeCommandArgument] = [],
            multilineArguments: [CMakeCommandArgument] = []) {
        var output = output // Safe because LineBasedTextOutputStream is a class
        output.beginLine(group: lineGroup ?? .named(command))
        output.write(command)
        output.write("(")
        for (index, argument) in headerArguments.enumerated() {
            if index > 0 { output.write(" ") }
            argument.write(to: &output)
        }
        if multilineArguments.isEmpty {
            output.write(")", endLine: true)
        }
        else {
            output.writeLineBlock {
                for argument in multilineArguments {
                    output.beginLine()
                    argument.write(to: &output)
                }
                output.write(")")
            }
        }
    }

    public func writeSingleLineCommand(
            lineGroup: LineBasedTextOutputStream.LineGroup? = nil,
            _ command: String,
            _ arguments: [CMakeCommandArgument]) {
        writeCommand(lineGroup: lineGroup, command, headerArguments: arguments)
    }

    public func writeSingleLineCommand(
            lineGroup: LineBasedTextOutputStream.LineGroup? = nil,
            _ command: String,
            _ arguments: CMakeCommandArgument...) {
        writeCommand(lineGroup: lineGroup, command, headerArguments: arguments)
    }

    public func writeAddLibrary(_ name: String, _ type: CMakeLibraryType? = nil, _ sources: [String] = []) {
        var headerArguments: [CMakeCommandArgument] = [ .autoquote(name) ]
        if let type { headerArguments.append(.unquoted(type.rawValue)) }
        writeCommand("add_library", headerArguments: headerArguments,
            multilineArguments: sources.map { .autoquote($0) })
    }

    public func writeTargetIncludeDirectories(_ target: String, _ visibility: CMakeVisibility, _ directories: [String]) {
        guard !directories.isEmpty else { return }
        writeCommand("target_include_directories",
            headerArguments: [ .autoquote(target), .unquoted(visibility.rawValue) ],
            multilineArguments: directories.map { .autoquote($0) })
    }

    public func writeTargetLinkLibraries(_ target: String, _ visibility: CMakeVisibility, _ libraries: [String]) {
        guard !libraries.isEmpty else { return }
        writeCommand("target_link_libraries",
            headerArguments: [ .autoquote(target), .unquoted(visibility.rawValue) ],
            multilineArguments: libraries.map { .autoquote($0) })
    }

    public func writeAddSubdirectory(_ source: String, _ binary: String? = nil) {
        var args: [CMakeCommandArgument] = [ .autoquote(source) ]
        if let binary { args.append(.autoquote(binary)) }
        writeSingleLineCommand("add_subdirectory", args)
    }
}