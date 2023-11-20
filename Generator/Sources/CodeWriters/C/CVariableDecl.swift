public struct CVariableDecl {
    public var type: CType
    public var name: String?

    public init(type: CType, name: String?) {
        self.type = type
        self.name = name
    }
}