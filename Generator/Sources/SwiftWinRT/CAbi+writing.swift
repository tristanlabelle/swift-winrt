import DotNetMetadata
import CodeWriters

extension CAbi {
    func writeEnum(_ enumDefinition: EnumDefinition, to writer: inout CSourceFileWriter) throws {
        let mangledName = CAbi.mangleName(type: enumDefinition.bind())

        func toValue(_ constant: Constant) -> Int {
            guard case let .int32(value) = constant else { fatalError() }
            return Int(value)
        }

        let enumerants = try enumDefinition.fields.filter { $0.isStatic && $0.visibility == .public }
            .map { CEnumerant(name: $0.name, value: toValue(try $0.literalValue!)) }

        writer.writeEnum(name: mangledName, enumerants: enumerants, enumerantPrefix: mangledName + "_")
    }

    func writeStruct(_ structDefinition: StructDefinition, to writer: inout CSourceFileWriter) throws {
        let mangledName = CAbi.mangleName(type: structDefinition.bind())

        let members = try structDefinition.fields.filter { !$0.isStatic && $0.visibility == .public  }
            .map { CDataMember(type: CAbi.toCType(try $0.type), name: $0.name) }

        writer.writeStruct(name: mangledName, members: members)
    }

    func writeInterface(_ interface: InterfaceDefinition, genericArgs: [TypeNode], to writer: inout CSourceFileWriter) throws {
        let mangledName = CAbi.mangleName(type: interface.bind(genericArgs: genericArgs))

        var functions = [CFunctionSignature]()

        // IUnknown members
        functions.append(.hresultReturning(name: "QueryInterface", params: [
            .init(type: .pointer(to: mangledName), name: "This"),
            .init(type: .init(name: "REFIID"), name: "riid"),
            .init(type: .init(name: "void", pointerIndirections: 2), name: "ppvObject")
        ]))
        functions.append(.init(returnType: "ULONG", name: "AddRef", params: [
            .init(type: .pointer(to: mangledName), name: "This")
        ]))
        functions.append(.init(returnType: "ULONG", name: "Release", params: [
            .init(type: .pointer(to: mangledName), name: "This")
        ]))

        // IInspectable members
        functions.append(.hresultReturning(name: "GetIids", params: [
            .init(type: .pointer(to: mangledName), name: "This"),
            .init(type: .pointer(to: "ULONG"), name: "iidCount"),
            .init(type: .init(name: "IID", pointerIndirections: 2), name: "iids")
        ]))
        functions.append(.hresultReturning(name: "GetRuntimeClassName", params: [
            .init(type: .pointer(to: mangledName), name: "This"),
            .init(type: .pointer(to: "HSTRING"), name: "className")
        ]))
        functions.append(.hresultReturning(name: "GetTrustLevel", params: [
            .init(type: .pointer(to: mangledName), name: "This"),
            .init(type: .pointer(to: "TrustLevel"), name: "trustLevel")
        ]))

        // Interface members
        for method in interface.methods {
            var params = [CFunctionSignature.Param]()

            params.append(.init(type: .pointer(to: mangledName), name: "This"))

            for param in try method.params {
                var type = CAbi.toCType(try param.type)
                if param.isByRef { type = type.withPointerIndirection() }
                params.append(.init(type: type, name: param.name))
            }

            let returnType = try method.returnType
            if !(returnType.asDefinition?.fullName == "System.Void") {
                params.append(.init(type: CAbi.toCType(returnType).withPointerIndirection(), name: nil))
            }

            functions.append(.hresultReturning(name: method.name, params: params))
        }

        writer.writeCOMInterface(
            name: mangledName,
            functions: functions,
            idName: CAbi.interfaceIDPrefix + mangledName,
            vtableName: mangledName + CAbi.interfaceVTableSuffix)
    }
}