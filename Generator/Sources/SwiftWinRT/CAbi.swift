import DotNetMetadata
import WindowsMetadata
import CodeWriters

enum CAbi {
    static func mangleName(type: BoundType) throws -> String {
        try WinRTTypeName.from(type: type).midlMangling
    }

    static func toCType(_ type: TypeNode) throws -> CType {
        guard case .bound(let type) = type else { fatalError() }
        return CType(
            name: try mangleName(type: type),
            pointerIndirections: type.definition.isReferenceType ? 1 : 0)
    }

    static func writeEnum(_ enumDefinition: EnumDefinition, to writer: inout CSourceFileWriter) throws {
        let mangledName = try mangleName(type: enumDefinition.bindType())

        func toValue(_ constant: Constant) -> Int {
            guard case let .int32(value) = constant else { fatalError() }
            return Int(value)
        }

        let enumerants = try enumDefinition.fields.filter { $0.isStatic && $0.visibility == .public }
            .map { CEnumerant(name: $0.name, value: toValue(try $0.literalValue!)) }

        writer.writeEnum(name: mangledName, enumerants: enumerants, enumerantPrefix: mangledName + "_")
    }

    static func writeStruct(_ structDefinition: StructDefinition, to writer: inout CSourceFileWriter) throws {
        let mangledName = try mangleName(type: structDefinition.bindType())

        let members = try structDefinition.fields.filter { !$0.isStatic && $0.visibility == .public  }
            .map { CDataMember(type: try toCType(try $0.type), name: $0.name) }

        writer.writeStruct(name: mangledName, members: members)
    }

    static func writeInterface(_ interface: InterfaceDefinition, genericArgs: [TypeNode], to writer: inout CSourceFileWriter) throws {
        let mangledName = try mangleName(type: interface.bindType(genericArgs: genericArgs))

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
                var type = try toCType(param.type)
                if param.isByRef { type = type.withPointerIndirection() }
                params.append(.init(type: type, name: param.name))
            }

            let returnType = try method.returnType
            if !(returnType.asDefinition?.fullName == "System.Void") {
                params.append(.init(type: try toCType(returnType).withPointerIndirection(), name: nil))
            }

            functions.append(.hresultReturning(name: method.name, params: params))
        }

        writer.writeCOMInterface(
            name: mangledName,
            functions: functions,
            idName: WinRTTypeName.midlInterfaceIDPrefix + mangledName,
            vtableName: mangledName + WinRTTypeName.midlVirtualTableSuffix)
    }
}