import class Foundation.FileManager

public class FileTextOutputStream: TextOutputStream {
    public enum DirectoryCreation {
        case none
        case parent
        case ancestors
    }

    public let path: String
    private let writeAtomically: Bool
    private let directoryCreation: DirectoryCreation
    public var text: String = String()

    public init(path: String, writeAtomically: Bool = false, directoryCreation: DirectoryCreation = .none) {
        self.path = path
        self.writeAtomically = writeAtomically
        self.directoryCreation = directoryCreation
    }

    public func write(_ string: String) {
        text.write(string)
    }

    deinit {
        do {
            if directoryCreation != .none, let lastDirectorySeparatorIndex = path.lastIndex(of: "\\") {
                let directoryPath = String(path[..<lastDirectorySeparatorIndex])
                try FileManager.default.createDirectory(
                    atPath: directoryPath,
                    withIntermediateDirectories: directoryCreation == .ancestors)
            }

            try text.write(toFile: path, atomically: writeAtomically, encoding: .utf8)
        }
        catch let error {
            assertionFailure(error.localizedDescription)
        }
    }
}