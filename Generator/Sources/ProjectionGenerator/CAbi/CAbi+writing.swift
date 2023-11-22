import CodeWriters
import DotNetMetadata
import WindowsMetadata

extension CAbi {
    public static func writeBasicTypeIncludes(to writer: CSourceFileWriter) {
        writer.writeInclude(pathSpec: "stdbool.h", kind: .angleBrackets)
        writer.writeInclude(pathSpec: "stdint.h", kind: .angleBrackets)
        writer.writeInclude(pathSpec: "uchar.h", kind: .angleBrackets)
    }

    public static func writeForwardDeclaration(type: BoundType, to writer: CSourceFileWriter) throws {
        writer.writeForwardDeclaration(
            kind: type.definition is EnumDefinition ? .enum : .struct,
            name: try CAbi.mangleName(type: type))
    }

    public static func writeEnum(_ enumDefinition: EnumDefinition, to writer: CSourceFileWriter) throws {
        let mangledName = try CAbi.mangleName(type: enumDefinition.bindType())

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

    public static func writeStruct(_ structDefinition: StructDefinition, to writer: CSourceFileWriter) throws {
        let mangledName = try CAbi.mangleName(type: structDefinition.bindType())

        let members = try structDefinition.fields.filter { !$0.isStatic && $0.visibility == .public  }
            .map { CVariableDecl(type: try toCType($0.type), name: $0.name) }

        writer.writeStruct(name: mangledName, members: members)
    }

    public static func writeCOMInterface(_ interface: InterfaceDefinition, genericArgs: [TypeNode], to writer: CSourceFileWriter) throws {
        let mangledName = try CAbi.mangleName(type: interface.bindType(genericArgs: genericArgs))

        var decl = COMInterfaceDecl(interfaceName: mangledName, inspectable: true)

        // Interface members
        for method in interface.methods {
            var params = [CParamDecl]()
            for param in try method.params {
                try appendCOMParams(for: param, genericArgs: genericArgs, to: &params)
            }

            if try method.hasReturnValue {
                let returnType = try method.returnType.bindGenericParams(typeArgs: genericArgs)
                params.append(CParamDecl(type: try toCType(returnType).makePointer(), name: nil))
            }

            decl.addFunction(name: method.name, params: params)
        }

        decl.write(to: writer)
    }

    private static func appendCOMParams(for param: Param, genericArgs: [TypeNode], to comParams: inout [CParamDecl]) throws {
        let paramType = try param.type.bindGenericParams(typeArgs: genericArgs)
        if case .array(let element) = paramType {
            var arrayLengthParamCType = CType.reference(name: "uint32_t")
            if param.isByRef { arrayLengthParamCType = arrayLengthParamCType.makePointer() }
            comParams.append(.init(type: arrayLengthParamCType, name: param.name.map { $0 + "Length" }))

            var arrayElementsCType = try toCType(element).makePointer()
            if param.isByRef { arrayElementsCType = arrayElementsCType.makePointer() }
            comParams.append(.init(type: arrayElementsCType, name: param.name))
        }
        else {
            var paramCType = try toCType(paramType)
            if param.isByRef { paramCType = paramCType.makePointer() }
            comParams.append(.init(type: paramCType, name: param.name))
        }
    }
}