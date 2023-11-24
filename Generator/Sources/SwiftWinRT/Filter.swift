internal enum Filter {
    case exact(String)
    case regex(Regex<AnyRegexOutput>)

    public init(pattern: String) {
        if pattern.contains("*") {
            var regexPattern = "^"
            regexPattern += Self.escapeRegexPattern(pattern)
            regexPattern.replace("\\*", with: ".*")
            regexPattern += "$"

            self = .regex(try! Regex<AnyRegexOutput>(regexPattern))
        }
        else {
            self = .exact(pattern)
        }
    }

    public func matches(_ value: String) -> Bool {
        switch self {
            case .exact(let filter): return value == filter
            case .regex(let regex): return (try? regex.wholeMatch(in: value)) != nil
        }
    }

    private static func escapeRegexPattern(_ pattern: String) -> String {
        var result = ""
        for char in pattern {
            if "[](){}+*.^$|?".contains(char) { result += "\\" }
            result.append(char)
        }
        return result
    }
}

internal struct FilterSet {
    private var filters: [Filter]?

    public init(_ filters: [Filter]?) {
        self.filters = filters
    }

    public func matches(_ value: String) -> Bool {
        guard let filters else { return true }
        return filters.contains { $0.matches(value) }
    }
}