extension SwiftPackage {
    public func write<Stream>(version: String = "5.8", to output: Stream) where Stream: AnyObject & TextOutputStream {
        let writer = IndentedTextOutputStream(inner: output)

        writer.writeFullLine(grouping: .never, "// swift-tools-version: \(version)")
        writer.writeFullLine(grouping: .never, "import PackageDescription")

        writer.writeIndentedBlock(header: "let package = Package(", footer: ")") {
            writer.write("name: \"\(name)\"")

            // products:
            if !products.isEmpty {
                writer.write(",", endLine: true)
                writer.writeIndentedBlock(header: "products: [") {
                    for (index, product) in products.enumerated() {
                        if index > 0 { writer.write(", ", endLine: true) }
                        product.write(to: writer)
                    }
                }
                writer.write("]")
            }

            // dependencies:
            if !dependencies.isEmpty {
                writer.write(",", endLine: true)
                writer.writeIndentedBlock(header: "dependencies: [") {
                    for (index, dependency) in dependencies.enumerated() {
                        if index > 0 { writer.write(", ", endLine: true) }
                        dependency.write(to: writer)
                    }
                }
                writer.write("]")
            }

            // targets:
            if !targets.isEmpty {
                writer.write(",", endLine: true)
                writer.writeIndentedBlock(header: "targets: [") {
                    for (index, target) in targets.enumerated() {
                        if index > 0 { writer.write(", ", endLine: true) }
                        target.write(to: writer)
                    }
                }
                writer.write("]")
            }
        }
    }
}

extension SwiftPackage.Product {
    fileprivate func write(to writer: IndentedTextOutputStream) {
        writer.writeIndentedBlock(header: ".library(") {
            writer.write("name: \"\(name)\"")
            if !targets.isEmpty {
                writer.write(",", endLine: true)
                writer.writeIndentedBlock(header: "targets: [") {
                    for (index, target) in targets.enumerated() {
                        if index > 0 { writer.write(", ", endLine: true) }
                        writer.write("\"\(target)\"")
                    }
                }
                writer.write("]")
            }
        }
        writer.write(")")
    }
}

extension SwiftPackage.Dependency {
    fileprivate func write(to writer: IndentedTextOutputStream) {
        writer.writeIndentedBlock(header: ".package(") {
            if let name { writer.write("name: \"\(name)\",", endLine: true) }
            writer.write("url: \"\(url)\",", endLine: true)
            writer.write("branch: \"\(branch)\"")
        }
        writer.write(")")
    }
}

extension SwiftPackage.Target {
    fileprivate func write(to writer: IndentedTextOutputStream) {
        writer.writeIndentedBlock(header: ".target(") {
            writer.write("name: \"\(name)\"")

            if !dependencies.isEmpty {
                writer.write(",", endLine: true)
                writer.writeIndentedBlock(header: "dependencies: [") {
                    for (index, dependency) in dependencies.enumerated() {
                        if index > 0 { writer.write(", ", endLine: true) }
                        dependency.write(to: writer)
                    }
                }
                writer.write("]")
            }

            if let path {
                writer.write(",", endLine: true)
                writer.write("path: \"\(path)\"")
            }
        }
        writer.write(")")
    }
}

extension SwiftPackage.Target.Dependency {
    fileprivate func write(to writer: IndentedTextOutputStream) {
        switch self {
            case .target(let name):
                writer.write("\"\(name)\"")
            case .product(let name, let package):
                writer.write(".product(name: \"\(name)\", package: \"\(package)\")")
        }
    }
}