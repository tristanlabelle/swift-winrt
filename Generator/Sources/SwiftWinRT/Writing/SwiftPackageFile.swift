import CodeWriters
import Collections
import DotNetMetadata
import ProjectionModel
import struct Foundation.URL

func writeSwiftPackageFile(_ projection: Projection, spmOptions: SPMOptions, toPath path: String) {
    var package = SwiftPackage(name: "Projection")
    package.dependencies.append(getSupportPackageDependency(reference: spmOptions.supportPackageReference))

    for module in projection.modulesByName.values {
        guard !module.isEmpty else { continue }

        // ABI module
        var abiModuleTarget: SwiftPackage.Target = .target(name: module.abiModuleName, path: "\(module.name)/ABI")
        abiModuleTarget.dependencies.append(.product(name: "WindowsRuntime_ABI", package: "Support"))
        package.targets.append(abiModuleTarget)

        // Swift module
        var projectionModuleTarget: SwiftPackage.Target = .target(name: module.name)
        projectionModuleTarget.path = "\(module.name)/Projection"
        projectionModuleTarget.dependencies.append(.product(name: "WindowsRuntime", package: "Support"))
        // Cannot add -whole-module-optimization like the CMake code because SPM already adds -enable-batch-mode

        for referencedModule in module.references {
            guard !referencedModule.isEmpty else { continue }
            abiModuleTarget.dependencies.append(.target(name: referencedModule.abiModuleName))
            projectionModuleTarget.dependencies.append(.target(name: referencedModule.name))
        }

        projectionModuleTarget.dependencies.append(.target(name: module.abiModuleName))

        package.targets.append(projectionModuleTarget)

        // Define a product for the module
        var moduleProduct: SwiftPackage.Product = .library(
            name: spmOptions.getLibraryName(moduleName: module.name),
            type: spmOptions.dynamicLibraries ? .dynamic : nil,
            targets: [])
        moduleProduct.targets.append(projectionModuleTarget.name)
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
                let compactNamespace = Projection.toCompactNamespace(namespace)
                namespaceModuleTarget.path = "\(module.name)/Namespaces/\(compactNamespace)"
                namespaceModuleTarget.dependencies.append(.target(name: module.name))
                package.targets.append(namespaceModuleTarget)
                moduleProduct.targets.append(namespaceModuleTarget.name)
            }
        }

        // Create products for the projections and the ABI
        package.products.append(moduleProduct)
        package.products.append(.library(
            name: spmOptions.getLibraryName(moduleName: module.abiModuleName),
            type: .static, targets: [abiModuleTarget.name]))
    }

    if spmOptions.excludeCMakeLists {
        // Assume every target has a root CMakeLists.txt file
        for targetIndex in package.targets.indices {
            package.targets[targetIndex].exclude.append("CMakeLists.txt")
        }
    }

    package.write(version: "5.10", to: FileTextOutputStream(path: path, directoryCreation: .ancestors))
}

fileprivate func getSupportPackageDependency(reference: String) -> SwiftPackage.Dependency {
    if reference.starts(with: "https://") {
        guard let fragmentSeparatorIndex = reference.lastIndex(of: "#") else {
            fatalError("Package URL reference should include # fragment: \(reference)")
        }

        let url = reference[..<fragmentSeparatorIndex]
        let fragment = reference[reference.index(after: fragmentSeparatorIndex)...]
        guard let equalIndex = fragment.firstIndex(of: "=") else {
            fatalError("Package URL fragment should include an assignment: \(reference)")
        }

        let lhs = fragment[..<equalIndex]
        let rhs = fragment[fragment.index(after: equalIndex)...]
        guard lhs == "branch" else {
            fatalError("Package URL fragment should include a branch assignment: \(reference)")
        }

        return .package(url: String(url), branch: String(rhs))
    } else {
        return .package(name: "Support", path: reference)
    }
}