public class FileTextOutputStream: TextOutputStream {
    public let path: String
    public var text: String = String()

    public init(path: String) {
        self.path = path
    }

    public func write(_ string: String) {
        text.write(string)
    }

    deinit {
        do {
            try text.write(toFile: path, atomically: true, encoding: .utf8)
        }
        catch let error {
            assertionFailure(error.localizedDescription)
        }
    }
}