public final class CMakeListsWriter {
    private let output: IndentedTextOutputStream

    public init(output: some TextOutputStream) {
        self.output = .init(inner: output)
    }

    public func writeAddLibrary(_ name: String, _ type: CMakeLibraryType? = nil, _ sources: [String] = []) {
        let typeSuffix = type.map { " \($0)" } ?? ""
        output.writeIndentedBlock(grouping: .never, header: "add_library(\(name)\(typeSuffix)", footer: ")") {
            for source in sources {
                output.writeFullLine(source)
            }
        }
    }

    public func writeTargetIncludeDirectories(_ target: String, _ visibility: CMakeVisibility, _ directories: [String]) {
        guard !directories.isEmpty else { return }
        output.writeIndentedBlock(grouping: .never, header: "target_include_directories(\(target) \(visibility)", footer: ")") {
            for directory in directories {
                output.writeFullLine(directory)
            }
        }
    }

    public func writeTargetLinkLibraries(_ target: String, _ visibility: CMakeVisibility, _ libraries: [String]) {
        guard !libraries.isEmpty else { return }
        output.writeIndentedBlock(grouping: .never, header: "target_link_libraries(\(target) \(visibility)", footer: ")") {
            for library in libraries {
                output.writeFullLine(library)
            }
        }
    }

    public func writeAddSubdirectory(_ subdirectory: String) {
        output.writeFullLine(grouping: .withName("add_subdirectory"), "add_subdirectory(\(subdirectory))")
    }
}