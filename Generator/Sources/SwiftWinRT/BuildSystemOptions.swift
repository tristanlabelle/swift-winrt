struct SPMOptions {
    public var supportPackageReference: String
    public var dynamicLibraries: Bool
    public var excludeCMakeLists: Bool
    public var moduleLibraryNameOverrides: [String: String]

    public func getLibraryName(moduleName: String) -> String {
        moduleLibraryNameOverrides[moduleName] ?? moduleName
    }

    public init?(commandLineArguments: CommandLineArguments, projectionConfig: ProjectionConfig) {
        guard commandLineArguments.generatePackageDotSwift else { return nil }

        self.supportPackageReference = commandLineArguments.spmSupportPackageReference
        self.dynamicLibraries = commandLineArguments.dynamicLibraries
        self.excludeCMakeLists = !commandLineArguments.generateCMakeLists

        self.moduleLibraryNameOverrides = .init()
        for (moduleName, moduleConfig) in projectionConfig.modules {
            if let libraryName = moduleConfig.spmLibraryName {
                self.moduleLibraryNameOverrides[moduleName] = libraryName
            }
        }
    }
}

struct CMakeOptions {
    public var dynamicLibraries: Bool
    public var moduleTargetNameOverrides: [String: String]

    public func getTargetName(moduleName: String) -> String {
        moduleTargetNameOverrides[moduleName] ?? moduleName
    }

    public init?(commandLineArguments: CommandLineArguments, projectionConfig: ProjectionConfig) {
        guard commandLineArguments.generateCMakeLists else { return nil }

        self.dynamicLibraries = commandLineArguments.dynamicLibraries

        self.moduleTargetNameOverrides = .init()
        for (moduleName, moduleConfig) in projectionConfig.modules {
            if let targetName = moduleConfig.cmakeTargetName {
                self.moduleTargetNameOverrides[moduleName] = targetName
            }
        }
    }
}