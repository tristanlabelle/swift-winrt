import ArgumentParser

struct GenerateCommand: ParsableCommand {
    @Option(name: .customLong("reference"), help: "A path to a .winmd file with the APIs to project.")
    var references: [String] = []

    @Option(name: .customLong("sdk"), help: "A Windows SDK version with the APIs to project.")
    var windowsSdkVersion: String? = nil

    @Option(name: .customLong("config"), help: "A path to a json projection configuration file to use.")
    var configFilePath: String? = nil

    @Option(name: .customLong("out"), help: "A path to the output directory.")
    var outputDirectoryPath: String

    @Flag(help: "Generate a package.swift file.")
    var package: Bool = false

    @Option(name: .customLong("out-manifest"), help: "Path to generate an embeddable exe manifest file to.")
    var exeManifestPath: String? = nil
}
