import CodeWriters
import Collections
import DotNetMetadata
import ProjectionModel
import struct Foundation.URL

func writeSwiftPackageFile(_ projection: SwiftProjection, supportPackageLocation: String, excludeCMakeLists: Bool, toPath path: String) {
    var package = SwiftPackage(name: "Projection")
    package.dependencies.append(getSupportPackageDependency(location: supportPackageLocation))

    var productTargets = [String]()

    for module in projection.modulesByName.values {
        guard !module.isEmpty else { continue }

        // ABI module
        var abiModuleTarget = SwiftPackage.Target(name: module.abiModuleName, path: "\(module.name)/ABI")
        abiModuleTarget.dependencies.append(.product(name: "WindowsRuntime_ABI", package: "swift-winrt"))
        package.targets.append(abiModuleTarget)

        // Assembly module
        var assemblyModuleTarget = SwiftPackage.Target(name: module.name)
        assemblyModuleTarget.path = "\(module.name)/Assembly"
        assemblyModuleTarget.dependencies.append(.product(name: "WindowsRuntime", package: "swift-winrt"))

        for referencedModule in module.references {
            guard !referencedModule.isEmpty else { continue }
            assemblyModuleTarget.dependencies.append(.target(name: referencedModule.name))
        }

        assemblyModuleTarget.dependencies.append(.target(name: module.abiModuleName))

        package.targets.append(assemblyModuleTarget)
        productTargets.append(assemblyModuleTarget.name)

        // Namespace modules
        if !module.flattenNamespaces {
            var namespaces = OrderedSet<String>()
            for typeDefinition in module.typeDefinitions {
                guard let namespace = typeDefinition.namespace else { continue }
                namespaces.append(namespace)
            }

            namespaces.sort()

            for namespace in namespaces {
                var namespaceModuleTarget = SwiftPackage.Target(
                    name: module.getNamespaceModuleName(namespace: namespace))
                let compactNamespace = SwiftProjection.toCompactNamespace(namespace)
                namespaceModuleTarget.path = "\(module.name)/Namespaces/\(compactNamespace)"
                namespaceModuleTarget.dependencies.append(.target(name: module.name))
                package.targets.append(namespaceModuleTarget)
                productTargets.append(namespaceModuleTarget.name)
            }
        }
    }

    if excludeCMakeLists {
        // Assume every target has a root CMakeLists.txt file
        for targetIndex in package.targets.indices {
            package.targets[targetIndex].exclude.append("CMakeLists.txt")
        }
    }

    package.products.append(.library(name: "Projection", targets: productTargets))

    package.write(version: "5.10", to: FileTextOutputStream(path: path, directoryCreation: .ancestors))
}

fileprivate func getSupportPackageDependency(location: String) -> SwiftPackage.Dependency {
    if location.starts(with: "https://") {
        if let separatorIndex = location.lastIndex(of: ":"),
                let lastSlashIndex = location.lastIndex(of: "/"),
                separatorIndex > lastSlashIndex {
            let url = String(location[..<separatorIndex])
            let branch = String(location[location.index(after: separatorIndex)...])
            return .package(url: url, branch: branch)
        }
        else {
            fatalError("Unexpected support package location format: \(location)")
        }
    } else {
        return .package(path: location)
    }
}