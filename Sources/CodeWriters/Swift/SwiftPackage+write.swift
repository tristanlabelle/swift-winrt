extension SwiftPackage {
    func write<Stream>(version: String = "5.8", to output: Stream) where Stream: AnyObject & TextOutputStream {
        let writer = IndentedTextOutputStream(inner: output)
        writer.writeLine(grouping: .never, "// swift-tools-version: \(version)")
        writer.writeLine(grouping: .never, "import PackageDescription")

        writer.writeIndentedBlock(header: "let package = Package(", footer: ")") {
            writer.write("name: \"\(name)\"")
            if !targets.isEmpty {
                writer.writeLine(",")
                writer.writeIndentedBlock(header: "targets: [", footer: "]") {
                    for target in targets {
                        target.write(to: writer)
                    }
                }
            }
        }
    }
}

extension SwiftPackage.Target {
    fileprivate func write(to writer: IndentedTextOutputStream) {
        writer.writeIndentedBlock(header: ".target(", footer: ")") {
            writer.write("name: \"\(name)\"")
            if !dependencies.isEmpty {
                writer.writeLine(",")
                writer.write("dependencies: [")
                var first = true
                for dependency in dependencies {
                    if !first { writer.writeLine(", ") }
                    writer.write("\"\(dependency)\"")
                    first = false
                }
                writer.writeLine("]")
            }
        }
    }
}