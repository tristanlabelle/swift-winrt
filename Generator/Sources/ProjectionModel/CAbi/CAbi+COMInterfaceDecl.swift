import CodeWriters

extension CAbi {
    internal struct COMInterfaceDecl {
        public var interfaceName: String
        public var members = [CVariableDecl]()

        public init(interfaceName: String, inspectable: Bool) {
            self.interfaceName = interfaceName

            // IUnknown members
            addFunction(name: "QueryInterface", params: [
                makeCParam(type: guidName, indirections: 1, name: "riid"),
                makeCParam(type: "void", indirections: 2, name: "ppvObject")
            ])
            addFunction(name: "AddRef", return: .reference(name: "uint32_t"))
            addFunction(name: "Release", return: .reference(name: "uint32_t"))

            // IInspectable members
            if inspectable {
                addFunction(name: "GetIids", params: [
                    makeCParam(type: "uint32_t", indirections: 1, name: "iidCount"),
                    makeCParam(type: guidName, indirections: 2, name: "iids")
                ])
                addFunction(name: "GetRuntimeClassName", params: [
                    makeCParam(type: hstringName, indirections: 1, name: "className")
                ])
                addFunction(name: "GetTrustLevel", params: [
                    makeCParam(type: namespacingPrefix + "TrustLevel", indirections: 1, name: "trustLevel")
                ])
            }
        }

        public mutating func addFunction(name: String, return: CType = .reference(name: hresultName), params: [CParamDecl] = []) {
            let params = [ makeCParam(type: interfaceName, indirections: 1, nullability: .nonnull, name: "_this") ] + params
            let typeSpecifier = CTypeSpecifier.functionPointer(
                return: `return`, callingConvention: .stdcall, params: params)
            members.append(CVariableDecl(type: CType(typeSpecifier), name: name))
        }

        public func write(comment: String? = nil, forwardDeclared: Bool = false, to writer: CSourceFileWriter) {
            writer.writeStruct(comment: comment, typedef: !forwardDeclared, name: interfaceName, members: [
                // Having the data member as "struct IFoo_VirtualTable*" forward declares the struct.
                .init(type: .reference(kind: .struct, name: interfaceName + CAbi.virtualTableSuffix).makePointer(), name: CAbi.virtualTableFieldName)
            ])

            writer.writeStruct(name: interfaceName + CAbi.virtualTableSuffix, members: members)
        }
    }
}