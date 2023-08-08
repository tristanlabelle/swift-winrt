struct ModuleMapFile: Codable {
    var modules: Dictionary<String, Module> = [:]

    struct Module: Codable {
        var assemblies: [String] = []
        var baseNamespace: String? = nil
        var includeFilters: [String]? = nil
    }
}