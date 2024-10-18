import ArgumentParser

struct CommandLineArguments: ParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "SwiftWinRT.exe",
            abstract: "A WinRT projections generator for Swift.")
    }

    @Option(name: .customLong("reference"), help: .init("A path to a .winmd file with the APIs to project.", valueName: "file"))
    var references: [String] = []

    @Option(name: .customLong("winsdk"), help: .init("A Windows SDK version with the APIs to project.", valueName: "version"))
    var windowsSdkVersion: String? = nil

    @Option(name: .customLong("config"), help: .init("A path to a json projection configuration file to use.", valueName: "file"))
    var configFilePath: String? = nil

    @Option(name: .customLong("locale"), help: .init("The locale(s) to prefer for documentation comments.", valueName: "code"))
    var locales: [String] = ["en-us", "en"]

    @Flag(name: .customLong("no-docs"), help: "Don't generate documentation comments.")
    var noDocs: Bool = false

    @Option(name: .customLong("out"), help: .init("A path to the output directory.", valueName: "dir"))
    var outputDirectoryPath: String

    public enum YesNoUnknown: String, Decodable, ExpressibleByArgument {
        case yes
        case no
        case unknown

        public init?(argument: String) { self.init(rawValue: argument) }

        public var asBool: Bool? {
            switch self {
                case .yes: return true
                case .no: return false
                case .unknown: return nil
            }
        }
    }

    @Option(
        name: .customLong("swift-bug-72724"),
        help: "Whether the compiler that will build the generated code is impacted by https://github.com/swiftlang/swift/issues/72724.")
    var swiftBug72724: YesNoUnknown = .unknown

    @Flag(name: .customLong("spm"), help: "Generate a package.swift file for building with SPM.")
    var generatePackageDotSwift: Bool = false

    @Option(name: .customLong("spm-library-prefix"), help: "A prefix to the module name when naming SPM libraries.")
    var spmLibraryPrefix: String = ""

    @Option(name: .customLong("spm-library-suffix"), help: "A suffix to the module name when naming SPM libraries.")
    var spmLibrarySuffix: String = ""

    @Option(name: .customLong("spm-support-package"), help: .init("The directory path or '<url>#branch=<branch>' of the support package to reference.", valueName: "dir-or-url"))
    var spmSupportPackageReference: String = "https://github.com/tristanlabelle/swift-winrt.git#branch=main"

    @Flag(name: .customLong("cmake"), help: "Generate build definitions for the CMake build system.")
    var generateCMakeLists: Bool = false

    @Option(name: .customLong("cmake-target-prefix"), help: "A prefix to the module name when naming CMake targets.")
    var cmakeTargetPrefix: String = ""

    @Option(name: .customLong("cmake-target-suffix"), help: "A suffix to the module name when naming CMake targets.")
    var cmakeTargetSuffix: String = ""

    @Flag(name: .customLong("dylib"), help: "Makes SPM and CMake build definitions specify to build dynamic libraries.")
    var dynamicLibraries: Bool = false

    @Option(name: .customLong("out-manifest"), help: .init("Path to generate an embeddable exe manifest file to.", valueName: "file"))
    var exeManifestPath: String? = nil
}
