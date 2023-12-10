extension String {
    func findPrefixEndIndex(_ prefix: String) -> String.Index? {
        var prefixIndex = prefix.startIndex
        var selfIndex = self.startIndex
        while prefixIndex != prefix.endIndex {
            guard selfIndex != self.endIndex, self[selfIndex] == prefix[prefixIndex] else { return nil }
            prefixIndex = prefix.index(after: prefixIndex)
            selfIndex = self.index(after: selfIndex)
        }

        return selfIndex
    }
}