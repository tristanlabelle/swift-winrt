public struct SwiftPackage {
    public var name: String
    public var products: [Product]
    public var dependencies: [Dependency]
    public var targets: [Target]

    public init(
            name: String,
            products: [Product] = [],
            dependencies: [Dependency] = [],
            targets: [Target] = []) {
        self.name = name
        self.products = products
        self.dependencies = dependencies
        self.targets = targets
    }

    public static func package(
            name: String,
            products: [Product] = [],
            dependencies: [Dependency] = [],
            targets: [Target] = []) -> SwiftPackage {
        .init(
            name: name,
            products: products,
            dependencies: dependencies,
            targets: targets)
    }

    public struct Product {
        public var name: String
        public var targets: [String]

        public static func library(name: String, targets: [String]) -> Product {
            .init(name: name, targets: targets)
        }
    }

    public enum Dependency {
        case fileSystem(name: String? = nil, path: String)
        case sourceControl(url: String, branch: String)

        public static func package(name: String? = nil, path: String) -> Dependency {
            .fileSystem(name: name, path: path)
        }

        public static func package(url: String, branch: String) -> Dependency {
            .sourceControl(url: url, branch: branch)
        }
    }

    public struct Target {
        public var name: String
        public var dependencies: [Dependency] = []
        public var path: String?

        public init(name: String, dependencies: [Dependency] = [], path: String? = nil) {
            self.name = name
            self.dependencies = dependencies
            self.path = path
        }

        public static func target(name: String, dependencies: [Dependency] = [], path: String? = nil) -> Target {
            .init(name: name, dependencies: dependencies, path: path)
        }

        public enum Dependency: ExpressibleByStringLiteral {
            case target(name: String)
            case product(name: String, package: String)

            public init(stringLiteral value: String) {
                self = .target(name: value)
            }
        }
    }
}