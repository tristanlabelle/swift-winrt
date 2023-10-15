import DotNetMetadata

enum WinMD {
    static func getDefaultInterface(for class: ClassDefinition) throws -> BoundType? {
        let baseInterface = try `class`.baseInterfaces.first {
            try $0.attributes.contains {
                try $0.type.fullName == "Windows.Foundation.Metadata.DefaultAttribute"
            }
        }

        return try baseInterface?.interface
    }
}