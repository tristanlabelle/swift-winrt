public struct CEnumerant {
    public var name: String
    public var value: Int?

    public init(name: String, value: Int? = nil) {
        self.name = name
        self.value = value
    }
}