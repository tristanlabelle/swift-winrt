struct SPMOptions {
    public let supportPackageReference: String
    public let libraryPrefix: String
    public let librarySuffix: String
    public let dynamicLibraries: Bool
    public let excludeCMakeLists: Bool

    public func getLibraryName(moduleName: String) -> String {
        "\(libraryPrefix)\(module)\(librarySuffix)"
    }
}

struct CMakeOptions {
    public let targetPrefix: String
    public let targetSuffix: String
    public let dynamicLibraries: Bool

    public func getTargetName(moduleName: String) -> String {
        "\(targetPrefix)\(module)\(targetSuffix)"
    }
}