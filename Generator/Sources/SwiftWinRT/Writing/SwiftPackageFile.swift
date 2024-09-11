import CodeWriters
import Collections
import DotNetMetadata
import ProjectionModel
import struct Foundation.URL

func writeSwiftPackageFile(
        _ projection: SwiftProjection,
        supportPackageLocation: String,
        excludeCMakeLists: Bool,
        dynamicLibraries: Bool,
        toPath path: String) {
    var package = SwiftPackage(name: "Projection")
    package.dependencies.append(getSupportPackageDependency(location: supportPackageLocation))

    for module in projection.modulesByName.values {
        guard !module.isEmpty else { continue }

        // ABI module
        var abiModuleTarget: SwiftPackage.Target = .target(name: module.abiModuleName, path: "\(module.name)/ABI")
        abiModuleTarget.dependencies.append(.product(name: "WindowsRuntime_ABI", package: "swift-winrt"))
        package.targets.append(abiModuleTarget)

        // Swift module
        var swiftModuleTarget: SwiftPackage.Target = .target(name: module.name)
        swiftModuleTarget.path = "\(module.name)/Module"
        swiftModuleTarget.dependencies.append(.product(name: "WindowsRuntime", package: "swift-winrt"))

        for referencedModule in module.references {
            guard !referencedModule.isEmpty else { continue }
            swiftModuleTarget.dependencies.append(.target(name: referencedModule.name))
        }

        swiftModuleTarget.dependencies.append(.target(name: module.abiModuleName))

        package.targets.append(swiftModuleTarget)

        // Define a product for the module
        var moduleProduct: SwiftPackage.Product = .library(name: module.name, type: dynamicLibraries ? .dynamic : nil, targets: [])
        moduleProduct.targets.append(swiftModuleTarget.name)
        moduleProduct.targets.append(abiModuleTarget.name)

        // Namespace modules
        if !module.flattenNamespaces {
            var namespaces = OrderedSet<String>()
            for typeDefinition in module.typeDefinitions {
                guard let namespace = typeDefinition.namespace else { continue }
                namespaces.append(namespace)
            }

            namespaces.sort()

            for namespace in namespaces {
                var namespaceModuleTarget: SwiftPackage.Target = .target(
                    name: module.getNamespaceModuleName(namespace: namespace))
                let compactNamespace = SwiftProjection.toCompactNamespace(namespace)
                namespaceModuleTarget.path = "\(module.name)/Namespaces/\(compactNamespace)"
                namespaceModuleTarget.dependencies.append(.target(name: module.name))
                package.targets.append(namespaceModuleTarget)
                moduleProduct.targets.append(namespaceModuleTarget.name)
            }
        }

        // Create products for the projections and the ABI
        package.products.append(moduleProduct)
        package.products.append(.library(name: module.abiModuleName, type: .static, targets: [abiModuleTarget.name]))
    }

    if excludeCMakeLists {
        // Assume every target has a root CMakeLists.txt file
        for targetIndex in package.targets.indices {
            package.targets[targetIndex].exclude.append("CMakeLists.txt")
        }
    }

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