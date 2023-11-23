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
        let mangledName = try CAbi.mangleName(type: type)
        if let enumDefinition = type.definition as? EnumDefinition {
            writer.writeTypedef(
                type: CType.reference(name: try enumDefinition.isFlags ? "uint32_t" : "int32_t"),
                name: mangledName)
        }
        else {
            writer.writeForwardDeclaration(typedef: true, kind: .struct, name: mangledName)
        }
    }

    public static func writeStruct(_ structDefinition: StructDefinition, to writer: CSourceFileWriter) throws {
        let mangledName = try CAbi.mangleName(type: structDefinition.bindType())

        let members = try structDefinition.fields.filter { !$0.isStatic && $0.visibility == .public  }
            .map { CVariableDecl(type: try toCType($0.type), name: $0.name) }

        writer.writeStruct(
            comment: try WinRTTypeName.from(type: structDefinition.bindType()).description,
            name: mangledName, members: members)
    }

    public static func writeCOMInterface(_ typeDefinition: TypeDefinition, genericArgs: [TypeNode], to writer: CSourceFileWriter) throws {
        precondition(typeDefinition is InterfaceDefinition || typeDefinition is DelegateDefinition)

        let boundType = typeDefinition.bindType(genericArgs: genericArgs)
        let mangledName = try CAbi.mangleName(type: boundType)

        var decl = COMInterfaceDecl(
            interfaceName: mangledName,
            inspectable: typeDefinition is InterfaceDefinition) // Delegates are not inspectable

        // Interface members
        for method in typeDefinition.methods {
            // For delegates, we only care about the invoke method
            guard !(typeDefinition is DelegateDefinition) || method.name == "Invoke" else { continue }

            var params = [CParamDecl]()
            for param in try method.params {
                try appendCOMParams(for: param, genericArgs: genericArgs, to: &params)
            }

            if try method.hasReturnValue {
                let returnType = try method.returnType.bindGenericParams(typeArgs: genericArgs)
                params.append(CParamDecl(
                    type: try toCType(returnType).makePointer(),
                    name: "_return"))
            }

            decl.addFunction(name: method.name, params: params)
        }

        decl.write(
            comment: try WinRTTypeName.from(type: boundType).description,
            to: writer)
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