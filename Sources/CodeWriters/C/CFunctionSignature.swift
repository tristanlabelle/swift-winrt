public struct CFunctionSignature {
    public var returnType: CType = .hresult
    public var name: String
    public var params: [Param]

    public struct Param {
        public var type: CType
        public var name: String?

        public init(type: CType, name: String?) {
            self.type = type
            self.name = name
        }
    }

    public init(returnType: CType, name: String, params: [Param]) {
        self.returnType = returnType
        self.name = name
        self.params = params
    }

    public static func hresultReturning(name: String, params: [Param]) -> CFunctionSignature {
        .init(returnType: .hresult, name: name, params: params)
    }
}
