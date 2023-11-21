import CodeWriters

extension CAbiHeaderWriter {
    internal struct COMType {
        public var name: String
        public var indirections: Int = 0

        public init(name: String, indirections: Int = 0) {
            self.name = name
            self.indirections = indirections
        }

        public func addingIndirection() -> Self {
            .init(name: name, indirections: indirections + 1)
        }

        public func toCType() -> CType {
            var type = CType.reference(name: name)
            for _ in 0..<indirections {
                type = type.makePointer()
            }
            return type
        }
    }

    internal struct COMParam {
        public var type: COMType
        public var name: String?

        public init(type: COMType, name: String?) {
            self.type = type
            self.name = name
        }

        public init(type: String, indirections: Int = 0, name: String?) {
            self.type = .init(name: type, indirections: indirections)
            self.name = name
        }

        public func toCParam() -> CParamDecl {
            .init(type: type.toCType(), name: name)
        }
    }

    internal struct COMInterfaceDecl {
        private let interfaceName: String
        private var members = [CVariableDecl]()

        public init(interfaceName: String, inspectable: Bool) {
            self.interfaceName = interfaceName

            // IUnknown members
            addFunction(name: "QueryInterface", params: [
                COMParam(type: "IID", indirections: 1, name: "riid"),
                COMParam(type: "void", indirections: 2, name: "ppvObject")
            ])
            addFunction(name: "AddRef", return: COMType(name: "uint32_t"))
            addFunction(name: "Release", return: COMType(name: "uint32_t"))

            // IInspectable members
            if inspectable {
                addFunction(name: "GetIids", params: [
                    COMParam(type: "uint32_t", indirections: 1, name: "iidCount"),
                    COMParam(type: "IID", indirections: 2, name: "iids")
                ])
                addFunction(name: "GetRuntimeClassName", params: [
                    COMParam(type: "HSTRING", indirections: 1, name: "className")
                ])
                addFunction(name: "GetTrustLevel", params: [
                    COMParam(type: "TrustLevel", indirections: 1, name: "trustLevel")
                ])
            }
        }

        public mutating func addFunction(name: String, return: COMType = .init(name: "HRESULT"), params: [COMParam] = []) {
            let params = [ CParamDecl(type: .reference(name: interfaceName).makePointer(), name: "_this") ]
                + params.map { $0.toCParam() }
            let typeSpecifier = CTypeSpecifier.functionPointer(
                return: `return`.toCType(), callingConvention: .stdcall, params: params)
            members.append(CVariableDecl(type: CType(typeSpecifier), name: name))
        }

        public func write(to writer: CSourceFileWriter) {
            writer.writeForwardDeclaration(kind: .struct, name: interfaceName)
            writer.writeStruct(name: interfaceName + CAbi.virtualTableSuffix, members: members)
            writer.writeStruct(name: interfaceName, members: [
                .init(type: .reference(name: interfaceName + CAbi.virtualTableSuffix).makePointer(), name: CAbi.virtualTableFieldName)
            ])
        }
    }
}