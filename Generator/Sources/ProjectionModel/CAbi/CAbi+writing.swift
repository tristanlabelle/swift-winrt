import CodeWriters
import DotNetMetadata
import WindowsMetadata

extension CAbi {
    public static func writeBasicTypeIncludes(to writer: CSourceFileWriter) {
        writer.writeInclude(pathSpec: "stdbool.h", kind: .angleBrackets)
        writer.writeInclude(pathSpec: "stdint.h", kind: .angleBrackets)
        writer.writeInclude(pathSpec: "uchar.h", kind: .angleBrackets)
    }

    public static func writeForwardDecl(type: BoundType, to writer: CSourceFileWriter) throws {
        if let enumDefinition = type.definition as? EnumDefinition {
            try writeEnumTypedef(enumDefinition, to: writer)
        }
        else {
            let mangledName = try CAbi.mangleName(type: type)
            writer.writeForwardDecl(typedef: true, kind: .struct, name: mangledName)
        }
    }

    public static func writeEnumTypedef(_ enumDefinition: EnumDefinition, to writer: CSourceFileWriter) throws {
        try writer.writeTypedef(
            type: .reference(name: enumDefinition.isFlags ? "uint32_t" : "int32_t"),
            name: CAbi.mangleName(type: enumDefinition.bindType()))
    }

    public static func writeStruct(_ structDefinition: StructDefinition, to writer: CSourceFileWriter) throws {
        let mangledName = try CAbi.mangleName(type: structDefinition.bindType())

        let members = try structDefinition.fields.filter { !$0.isStatic && $0.visibility == .public  }
            .map { CVariableDecl(type: try toCType($0.type), name: $0.name) }

        writer.writeStruct(
            comment: try WinRTTypeName.from(type: structDefinition.bindType()).description,
            typedef: true,  name: mangledName, members: members)
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
                try appendCOMParams(name: param.name, type: try param.type, genericArgs: genericArgs, isByRef: param.isByRef, to: &params)
            }

            if try method.hasReturnValue {
                try appendCOMParams(name: "_return", type: try method.returnType, genericArgs: genericArgs, isByRef: true, to: &params)
            }

            decl.addFunction(
                name: try method.findAttribute(OverloadAttribute.self)?.methodName ?? method.name,
                params: params)
        }

        if !genericArgs.isEmpty {
            // No module owns a generic type instantiation, so use #define guards to prevent multiple definitions.
            let lineGroup = writer.output.createLineGroup()
            writer.output.writeFullLine(group: lineGroup, "#ifndef \(mangledName)")
            writer.output.writeFullLine(group: lineGroup, "#define \(mangledName) \(mangledName)", groupWithNext: true)
        }

        decl.write(
            comment: try WinRTTypeName.from(type: boundType).description,
            forwardDeclared: true,
            to: writer)

        if !genericArgs.isEmpty {
            writer.output.endLine(groupWithNext: true)
            writer.output.writeFullLine(group: .none, "#endif")
        }
    }

    private static func appendCOMParams(name: String?, type: TypeNode, genericArgs: [TypeNode], isByRef: Bool, to comParams: inout [CParamDecl]) throws {
        let paramType = type.bindGenericParams(typeArgs: genericArgs)
        if case .array(let element) = paramType {
            var arrayLengthParamCType = CType.reference(name: "uint32_t")
            if isByRef { arrayLengthParamCType = arrayLengthParamCType.makePointer() }
            comParams.append(.init(type: arrayLengthParamCType, name: name.map { $0 + "Length" }))

            var arrayElementsCType = try toCType(element).makePointer()
            if isByRef { arrayElementsCType = arrayElementsCType.makePointer() }
            comParams.append(.init(type: arrayElementsCType, name: name))
        }
        else {
            var paramCType = try toCType(paramType)
            if isByRef { paramCType = paramCType.makePointer() }
            comParams.append(.init(type: paramCType, name: name))
        }
    }
}