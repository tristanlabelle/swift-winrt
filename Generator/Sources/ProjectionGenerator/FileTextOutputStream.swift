internal class FileTextOutputStream: TextOutputStream {
    let path: String
    var text: String = String()

    init(path: String) {
        self.path = path
    }

    func write(_ string: String) {
        text.write(string)
    }

    deinit {
        try? text.write(toFile: path, atomically: true, encoding: .utf8)
    }
}