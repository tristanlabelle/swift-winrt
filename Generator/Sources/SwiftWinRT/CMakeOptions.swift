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