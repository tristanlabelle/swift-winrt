public enum SwiftVisibility {
    case implicit
    case `internal`
    case `private`
    case `fileprivate`
    case `public`
    case `open`
}

extension SwiftVisibility: CustomStringConvertible, TextOutputStreamable {
    public var description: String {
        var result = ""
        write(to: &result, trailingSpace: false)
        return result
    }

    public func write(to output: inout some TextOutputStream) {
        write(to: &output, trailingSpace: false)
    }

    public func write(to output: inout some TextOutputStream, trailingSpace: Bool) {
        switch self {
            case .implicit: return
            case .internal: output.write("internal")
            case .private: output.write("private")
            case .fileprivate: output.write("fileprivate")
            case .public: output.write("public")
            case .open: output.write("open")
        }

        if trailingSpace { output.write(" ") }
    }
}