public enum Casing {
    public static func pascalToCamel(_ str: String) -> String {
        // "" -> ""
        // fooBar -> fooBar
        guard str.first?.isUppercase == true else { return str }
        var lastUpperCaseIndex = str.startIndex
        while true {
            let nextIndex = str.index(after: lastUpperCaseIndex)
            guard nextIndex < str.endIndex else { break }
            guard str[nextIndex].isUppercase else { break }
            lastUpperCaseIndex = nextIndex
        }

        let firstNonUpperCaseIndex = str.index(after: lastUpperCaseIndex)

        // FOOBAR -> foobar
        if firstNonUpperCaseIndex == str.endIndex {
            return str.lowercased()
        }

        // FooBar -> fooBar
        if lastUpperCaseIndex == str.startIndex {
            return str[lastUpperCaseIndex].lowercased() + str[firstNonUpperCaseIndex...]
        }

        // UIElement -> uiElement
        return str[...lastUpperCaseIndex].lowercased() + str[firstNonUpperCaseIndex...]
    }
}