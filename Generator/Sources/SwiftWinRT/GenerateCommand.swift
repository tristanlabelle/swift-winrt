import ArgumentParser

struct GenerateCommand: ParsableCommand {
    @Option(name: .customLong("reference"), help: "A path to a .winmd file with the APIs to project.")
    var references: [String] = []

    @Option(help: "A Windows SDK version with the APIs to project.")
    var sdk: String? = nil

    @Option(help: "A path to a json projection configuration file to use.")
    var config: String? = nil

    @Option(help: "A path to the output directory.")
    var out: String

    @Flag(help: "Generate a package.swift file.")
    var package: Bool = false
}
