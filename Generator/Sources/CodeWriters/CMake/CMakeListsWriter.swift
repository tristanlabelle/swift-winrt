public final class CMakeListsWriter {
    private let output: IndentedTextOutputStream

    public init(output: some TextOutputStream) {
        self.output = .init(inner: output)
    }

    public func writeCommand(_ command: String, headerArguments: [CMakeCommandArgument] = [], multilineArguments: [CMakeCommandArgument] = []) {
        var output = output // Safe because IndentedTextOutputStream is a class
        output.beginLine(grouping: .withName(command))
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
            output.writeIndentedBlock {
                for argument in multilineArguments {
                    output.beginLine()
                    argument.write(to: &output)
                }
            }
            output.write(")", endLine: true)
        }
    }

    public func writeSingleLineCommand(_ command: String, _ arguments: [CMakeCommandArgument]) {
        writeCommand(command, headerArguments: arguments)
    }

    public func writeSingleLineCommand(_ command: String, _ arguments: CMakeCommandArgument...) {
        writeCommand(command, headerArguments: arguments)
    }

    public func writeAddLibrary(_ name: CMakeCommandArgument, _ type: CMakeLibraryType? = nil, _ sources: [CMakeCommandArgument] = []) {
        var headerArguments = [ name ]
        if let type { headerArguments.append(.unquoted(type.rawValue)) }
        writeCommand("add_library", headerArguments: headerArguments, multilineArguments: sources)
    }

    public func writeTargetIncludeDirectories(_ target: CMakeCommandArgument, _ visibility: CMakeVisibility, _ directories: [CMakeCommandArgument]) {
        guard !directories.isEmpty else { return }
        writeCommand("target_include_directories", headerArguments: [ target, .unquoted(visibility.rawValue) ], multilineArguments: directories)
    }

    public func writeTargetLinkLibraries(_ target: CMakeCommandArgument, _ visibility: CMakeVisibility, _ libraries: [CMakeCommandArgument]) {
        guard !libraries.isEmpty else { return }
        writeCommand("target_link_libraries", headerArguments: [ target, .unquoted(visibility.rawValue) ], multilineArguments: libraries)
    }

    public func writeAddSubdirectory(_ source: CMakeCommandArgument, _ binary: CMakeCommandArgument? = nil) {
        writeSingleLineCommand("add_subdirectory", binary.map { [source, $0] } ?? [source])
    }
}