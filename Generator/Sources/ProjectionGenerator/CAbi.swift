import DotNetMetadata
import WindowsMetadata
import CodeWriters

public enum CAbi {
    public static func mangleName(type: BoundType) throws -> String {
        try WinRTTypeName.from(type: type).midlMangling
    }

    public static func toCType(_ type: TypeNode) throws -> CType {
        guard case .bound(let type) = type else { fatalError() }
        var ctype: CType = .reference(name: try mangleName(type: type))
        if type.definition.isReferenceType { ctype = ctype.makePointer() }
        return ctype
    }

    public static func writeEnum(_ enumDefinition: EnumDefinition, to writer: inout CSourceFileWriter) throws {
        let mangledName = try mangleName(type: enumDefinition.bindType())

        func toValue(_ constant: Constant) -> Int {
            switch constant {
                case .int32(let value): return Int(value) // Non-flags
                case .uint32(let value): return Int(value) // Flags
                default: fatalError()
            }
        }

        let enumerants = try enumDefinition.fields.filter { $0.isStatic && $0.visibility == .public }
            .map { CEnumerant(name: $0.name, value: toValue(try $0.literalValue!)) }

        writer.writeEnum(name: mangledName, enumerants: enumerants, enumerantPrefix: mangledName + "_")
    }

    public static func writeStruct(_ structDefinition: StructDefinition, to writer: inout CSourceFileWriter) throws {
        let mangledName = try mangleName(type: structDefinition.bindType())

        let members = try structDefinition.fields.filter { !$0.isStatic && $0.visibility == .public  }
            .map { CVariableDecl(type: try toCType(try $0.type), name: $0.name) }

        writer.writeStruct(name: mangledName, members: members)
    }

    public static func writeInterface(_ interface: InterfaceDefinition, genericArgs: [TypeNode], to writer: inout CSourceFileWriter) throws {
        let mangledName = try mangleName(type: interface.bindType(genericArgs: genericArgs))

        var functions = [CVariableDecl]()
        func addFunction(name: String, return: String = "HRESULT", params: [CVariableDecl] = []) {
            let thisParam = CVariableDecl(type: .reference(name: mangledName).makePointer(), name: "This")
            let typeSpecifier = CTypeSpecifier.functionPointer(
                return: .reference(name: `return`),
                callingConvention: .stdcall,
                params: [ thisParam ] + params)
            functions.append(CVariableDecl(type: CType(typeSpecifier), name: name))
        }

        // IUnknown members
        addFunction(name: "QueryInterface", params: [
            .init(type: .reference(name: "REFIID"), name: "riid"),
            .init(type: .reference(name: "void").makePointer().makePointer(), name: "ppvObject")
        ])
        addFunction(name: "AddRef", return: "ULONG")
        addFunction(name: "Release", return: "ULONG")

        // IInspectable members
        addFunction(name: "GetIids", return: "ULONG", params: [
            .init(type: .reference(name: "ULONG").makePointer(), name: "iidCount"),
            .init(type: .reference(name: "IID").makePointer().makePointer(), name: "iids")
        ])
        addFunction(name: "GetRuntimeClassName", params: [
            .init(type: .reference(name: "HSTRING").makePointer(), name: "className")
        ])
        addFunction(name: "GetTrustLevel", params: [
            .init(type: .reference(name: "TrustLevel").makePointer(), name: "trustLevel")
        ])

        // Interface members
        for method in interface.methods {
            var params = [CVariableDecl]()
            for param in try method.params {
                try appendCParams(for: param, genericArgs: genericArgs, to: &params)
            }

            let returnType = try method.returnType.bindGenericParams(typeArgs: genericArgs)
            if !(returnType.asDefinition?.fullName == "System.Void") {
                params.append(.init(type: try toCType(returnType).makePointer(), name: nil))
            }

            addFunction(name: method.name, params: params)
        }

        writer.writeStruct(name: mangledName + WinRTTypeName.midlVirtualTableSuffix, members: functions)
        writer.writeStruct(name: mangledName, members: [
            .init(type: .reference(name: mangledName + WinRTTypeName.midlVirtualTableSuffix).makePointer(), name: "lpVtbl")
        ])
    }

    private static func appendCParams(for param: Param, genericArgs: [TypeNode], to cparams: inout [CVariableDecl]) throws {
        let paramType = try param.type.bindGenericParams(typeArgs: genericArgs)
        if case .array(let element) = paramType {
            var arrayLengthParamCType = CType.reference(name: "UINT32")
            if param.isByRef { arrayLengthParamCType = arrayLengthParamCType.makePointer() }
            cparams.append(.init(type: arrayLengthParamCType, name: param.name.map { $0 + "Length" }))

            var arrayElementsCType = try toCType(element).makePointer()
            if param.isByRef { arrayElementsCType = arrayElementsCType.makePointer() }
            cparams.append(.init(type: arrayElementsCType, name: param.name))
        }
        else {
            var paramCType = try toCType(paramType)
            if param.isByRef { paramCType = paramCType.makePointer() }
            cparams.append(.init(type: paramCType, name: param.name))
        }
    }
}