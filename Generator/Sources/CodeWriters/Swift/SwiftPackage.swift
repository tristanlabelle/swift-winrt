public struct SwiftPackage {
    public var name: String
    public var targets: [Target]

    public struct Target {
        public var name: String
        public var dependencies: [String] = []
    }
}