struct ModuleMapFile: Codable {
    var modules: Dictionary<String, Module> = [:]

    struct Module: Codable {
        var assemblies: [String] = []
        var includeFilters: [String]? = nil
    }
}