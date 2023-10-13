import DotNetMetadata

extension Method {
    var isAccessor: Bool {
        let prefixes = [ "get_", "set_", "put_", "add_", "remove_"]
        return prefixes.contains(where: { name.starts(with: $0) })
    }
}