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

    @Flag(name: .customLong("spm"), help: "Generate a package.swift file for building with SPM.")
    var generatePackageDotSwift: Bool = false

    @Option(name: .customLong("support"), help: .init("The directory path or url:branch or url@revision of the support package to use.", valueName: "dir-or-url"))
    var supportPackageLocation: String = "https://github.com/tristanlabelle/swift-winrt.git:main"

    @Flag(name: .customLong("cmakelists"), help: "Generate a CMakeLists.txt files for building with CMake.")
    var generateCMakeLists: Bool = false

    @Flag(name: .customLong("dylib"), help: "Makes SPM and CMake build definitions specify to build dynamic libraries.")
    var dynamicLibraries: Bool = false

    @Option(name: .customLong("out-manifest"), help: .init("Path to generate an embeddable exe manifest file to.", valueName: "file"))
    var exeManifestPath: String? = nil
}
