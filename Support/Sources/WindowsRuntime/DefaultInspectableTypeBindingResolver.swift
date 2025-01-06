import func Foundation.NSClassFromString

/// Creates Swift wrappers for COM objects based on runtime type information,
/// which allows for instantiating subclass wrappers and upcasting.
public class DefaultInspectableTypeBindingResolver: InspectableTypeBindingResolver {
    private let namespacesToModuleNames: [Substring: String] // Store keys as substrings for lookup by substring
    private var bindingTypeCache: [String: (any InspectableTypeBinding.Type)?] = [:]
    private let cacheFailedLookups: Bool

    public init(namespacesToModuleNames: [String: String], cacheFailedLookups: Bool = false) {
        // Convert keys to substrings for lookup by substring (won't leak a larger string)
        var namespaceSubstringsToModuleNames = [Substring: String](minimumCapacity: namespacesToModuleNames.count)
        for (namespace, module) in namespacesToModuleNames {
            namespaceSubstringsToModuleNames[namespace[...]] = module
        }

        self.namespacesToModuleNames = namespaceSubstringsToModuleNames
        self.cacheFailedLookups = cacheFailedLookups
    }

    public func resolve(typeName: String) -> (any InspectableTypeBinding.Type)? {
        if let cachedBindingType = bindingTypeCache[typeName] { return cachedBindingType }

        let bindingType = lookup(typeName: typeName)
        if bindingType != nil || cacheFailedLookups {
            bindingTypeCache[typeName] = bindingType
        }

        return bindingType
    }

    private func lookup(typeName: String) -> (any InspectableTypeBinding.Type)? {
        guard let lastDotIndex = typeName.lastIndex(of: ".") else { return nil }
        guard let moduleName = toModuleName(namespace: typeName[..<lastDotIndex]) else { return nil }

        // ModuleName.NamespaceSubnamespace_TypeNameBinding
        var bindingClassName = moduleName
        bindingClassName += "."
        for typeNameChar in typeName[..<lastDotIndex] {
            guard typeNameChar != "." else { continue }
            bindingClassName.append(typeNameChar)
        }
        bindingClassName += "_"
        bindingClassName += typeName[typeName.index(after: lastDotIndex)...]
        bindingClassName += "Binding"

        return NSClassFromString(bindingClassName) as? any InspectableTypeBinding.Type
    }

    private func toModuleName(namespace: Substring) -> String? {
        var namespace = namespace
        while true {
            guard !namespace.isEmpty else { return nil }
            if let module = namespacesToModuleNames[namespace] { return module }
            guard let lastDotIndex = namespace.lastIndex(of: ".") else { return nil }
            namespace = namespace[..<lastDotIndex]
        }
    }
}