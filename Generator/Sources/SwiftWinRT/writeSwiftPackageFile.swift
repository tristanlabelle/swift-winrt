import CodeWriters
import DotNetMetadata
import ProjectionGenerator

func writeSwiftPackageFile(_ projection: SwiftProjection, toPath path: String) {
    var package = SwiftPackage(name: "Projection")

    package.dependencies.append(.package(url: "https://github.com/tristanlabelle/swift-winrt.git", branch: "main"))

    package.targets.append(
        .target(name: projection.abiModuleName, path: projection.abiModuleName))

    var productTargets = [String]()

    for module in projection.modulesByName.values {
        guard !module.isEmpty else { continue }

        // Assembly module
        var assemblyModuleTarget = SwiftPackage.Target(name: module.name)
        assemblyModuleTarget.path = "\(module.name)/Assembly"

        assemblyModuleTarget.dependencies.append(.product(name: "WindowsRuntime", package: "swift-winrt"))

        for referencedModule in module.references {
            guard !referencedModule.isEmpty else { continue }
            assemblyModuleTarget.dependencies.append(.target(name: referencedModule.name))
        }

        assemblyModuleTarget.dependencies.append(.target(name: projection.abiModuleName))

        package.targets.append(assemblyModuleTarget)
        productTargets.append(assemblyModuleTarget.name)

        // Namespace modules
        if !module.flattenNamespaces {
            for (namespace, _) in module.typeDefinitionsByNamespace {
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

    package.products.append(.library(name: "Projection", targets: productTargets))

    package.write(to: FileTextOutputStream(path: path))
}