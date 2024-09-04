extension SwiftPackage {
    public func write<Stream>(version: String, to output: Stream) where Stream: AnyObject & TextOutputStream {
        let writer = IndentedTextOutputStream(inner: output)

        writer.writeFullLine(grouping: .never, "// swift-tools-version: \(version)")
        writer.writeFullLine(grouping: .never, "import PackageDescription")

        writer.writeIndentedBlock(header: "let package = Package(", footer: ")") {
            writer.write("name: \"\(escapeStringLiteral(name))\"")

            // products:
            if !products.isEmpty {
                writer.write(",", endLine: true)
                writer.writeIndentedBlock(header: "products: [", footer: "]", endFooterLine: false) {
                    for (index, product) in products.enumerated() {
                        if index > 0 { writer.write(", ", endLine: true) }
                        product.write(to: writer)
                    }
                }
            }

            // dependencies:
            if !dependencies.isEmpty {
                writer.write(",", endLine: true)
                writer.writeIndentedBlock(header: "dependencies: [", footer: "]", endFooterLine: false) {
                    for (index, dependency) in dependencies.enumerated() {
                        if index > 0 { writer.write(", ", endLine: true) }
                        dependency.write(to: writer)
                    }
                }
            }

            // targets:
            if !targets.isEmpty {
                writer.write(",", endLine: true)
                writer.writeIndentedBlock(header: "targets: [", footer: "]", endFooterLine: false) {
                    for (index, target) in targets.enumerated() {
                        if index > 0 { writer.write(", ", endLine: true) }
                        target.write(to: writer)
                    }
                }
            }
        }
    }
}

extension SwiftPackage.Product {
    fileprivate func write(to writer: IndentedTextOutputStream) {
        writer.writeIndentedBlock(header: ".library(", footer: ")", endFooterLine: false) {
            writer.write("name: \"\(escapeStringLiteral(name))\"")
            if !targets.isEmpty {
                writer.write(",", endLine: true)
                writer.writeIndentedBlock(header: "targets: [", footer: "]", endFooterLine: false) {
                    for (index, target) in targets.enumerated() {
                        if index > 0 { writer.write(", ", endLine: true) }
                        writer.write("\"\(escapeStringLiteral(target))\"")
                    }
                }
            }
        }
    }
}

extension SwiftPackage.Dependency {
    fileprivate func write(to writer: IndentedTextOutputStream) {
        writer.writeIndentedBlock(header: ".package(", footer: ")", endFooterLine: false) {
            switch self {
                case .fileSystem(let name, let path):
                    if let name { writer.write("name: \"\(name)\",", endLine: true) }
                    writer.write("path: \"\(escapeStringLiteral(path))\"")
                case .sourceControl(let url, let branch):
                    writer.write("url: \"\(escapeStringLiteral(url))\",", endLine: true)
                    writer.write("branch: \"\(escapeStringLiteral(branch))\"")
            }
        }
    }
}

extension SwiftPackage.Target {
    fileprivate func write(to writer: IndentedTextOutputStream) {
        writer.writeIndentedBlock(header: ".target(", footer: ")", endFooterLine: false) {
            writer.write("name: \"\(escapeStringLiteral(name))\"")

            if !dependencies.isEmpty {
                writer.write(",", endLine: true)
                writer.writeIndentedBlock(header: "dependencies: [", footer: "]", endFooterLine: false) {
                    for (index, dependency) in dependencies.enumerated() {
                        if index > 0 { writer.write(", ", endLine: true) }
                        dependency.write(to: writer)
                    }
                }
            }

            if let path {
                writer.write(",", endLine: true)
                writer.write("path: \"\(escapeStringLiteral(path))\"")
            }

            if !exclude.isEmpty {
                writer.write(",", endLine: true)
                writer.writeIndentedBlock(header: "exclude: [", footer: "]", endFooterLine: false) {
                    for (index, path) in exclude.enumerated() {
                        if index > 0 { writer.write(", ", endLine: true) }
                            writer.write("\"")
                            writer.write(path.replacingOccurrences(of: "\\", with: "\\\\"))
                            writer.write("\"")
                    }
                }
            }

            if !cUnsafeFlags.isEmpty {
                writer.write(",", endLine: true)
                writer.writeIndentedBlock(header: "cSettings: [", footer: "]", endFooterLine: false) {
                    writer.writeIndentedBlock(header: ".unsafeFlags([", footer: "]", endFooterLine: false) {
                        for (index, flag) in cUnsafeFlags.enumerated() {
                            if index > 0 { writer.write(", ", endLine: true) }
                            writer.write("\"")
                            writer.write(flag)
                            writer.write("\"")
                        }
                    }
                }
            }
        }
    }
}

extension SwiftPackage.Target.Dependency {
    fileprivate func write(to writer: IndentedTextOutputStream) {
        switch self {
            case .target(let name):
                writer.write("\"\(name)\"")
            case .product(let name, let package):
                writer.write(".product(name: \"\(escapeStringLiteral(name))\", package: \"\(escapeStringLiteral(package))\")")
        }
    }
}

fileprivate func escapeStringLiteral(_ string: String) -> String {
    string
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "\n", with: "\\n")
        .replacingOccurrences(of: "\r", with: "\\r")
        .replacingOccurrences(of: "\t", with: "\\t")
}