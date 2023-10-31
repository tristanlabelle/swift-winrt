import ArgumentParser

struct GenerateCommand: ParsableCommand {
    @Option(name: .customLong("reference"), help: "A path to a .winmd file with the APIs to project.")
    var references: [String] = []

    @Option(help: "A Windows SDK version with the APIs to project.")
    var sdk: String? = nil

    @Option(name: .customLong("module-map"), help: "A path to a module map json file to use.")
    var moduleMap: String? = nil

    @Option(name: .customLong("abi-module"), help: "The name of the C ABI module.")
    var abiModuleName: String = "CAbi"

    @Option(help: "A path to the output directory.")
    var out: String
}
