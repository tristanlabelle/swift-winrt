import CodeWriters
import DotNetMetadata
import WindowsMetadata

public class CAbiHeaderWriter {
    private let writer: CSourceFileWriter

    public init(output: some TextOutputStream) {
        self.writer = .init(output: output)

        writer.writeInclude(pathSpec: "stdint.h", kind: .angleBrackets)
    }

    public func writeInclude(header: String) {
        writer.writeInclude(pathSpec: header, kind: .doubleQuotes)
    }

    public func writeForwardDeclaration(type: BoundType) throws {
        writer.writeForwardDeclaration(
            kind: type.definition is EnumDefinition ? .enum : .struct,
            name: try CAbi.mangleName(type: type))
    }

    public func writeEnum(_ enumDefinition: EnumDefinition) throws {
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

    public func writeStruct(_ structDefinition: StructDefinition) throws {
        let mangledName = try CAbi.mangleName(type: structDefinition.bindType())

        let members = try structDefinition.fields.filter { !$0.isStatic && $0.visibility == .public  }
            .map { CVariableDecl(type: try toCOMType($0.type).toCType(), name: $0.name) }

        writer.writeStruct(name: mangledName, members: members)
    }

    public func writeCOMInterface(_ interface: InterfaceDefinition, genericArgs: [TypeNode]) throws {
        let mangledName = try CAbi.mangleName(type: interface.bindType(genericArgs: genericArgs))

        var decl = COMInterfaceDecl(interfaceName: mangledName, inspectable: true)

        // Interface members
        for method in interface.methods {
            var params = [COMParam]()
            for param in try method.params {
                try appendCOMParams(for: param, genericArgs: genericArgs, to: &params)
            }

            if try method.hasReturnValue {
                let returnType = try method.returnType.bindGenericParams(typeArgs: genericArgs)
                params.append(COMParam(type: try toCOMType(returnType).addingIndirection(), name: nil))
            }

            decl.addFunction(name: method.name, params: params)
        }

        decl.write(to: writer)
    }

    private func toCOMType(_ type: TypeNode) throws -> COMType {
        guard case .bound(let type) = type else { fatalError() }

        if type.definition.namespace == "System" {
            switch type.definition.name {
                case "Void": return .init(name: "void")

                case "SByte": return .init(name: "int8_t")
                case "Byte": return .init(name: "uint8_t")
                case "Int16": return .init(name: "int16_t")
                case "UInt16": return .init(name: "uint16_t")
                case "Int32": return .init(name: "int32_t")
                case "UInt32": return .init(name: "uint32_t")
                case "Int64": return .init(name: "int64_t")
                case "UInt64": return .init(name: "uint64_t")
                case "IntPtr": return .init(name: "intptr_t")
                case "UIntPtr": return .init(name: "uintptr_t")

                case "Single": return .init(name: "float")
                case "Double": return .init(name: "double")

                // TODO: Define own types for these
                case "Boolean": return .init(name: "uint8_t")
                case "Char": return .init(name: "uint16_t")
                case "Object": return .init(name: "IInspectable")
                case "String": return .init(name: "HSTRING")
                case "Guid": return .init(name: "GUID")
                default: fatalError("Not implemented")
            }
        }

        var comType = COMType(name: try CAbi.mangleName(type: type))
        if type.definition.isReferenceType { comType.indirections += 1 }
        return comType
    }

    private func appendCOMParams(for param: Param, genericArgs: [TypeNode], to comParams: inout [COMParam]) throws {
        let paramType = try param.type.bindGenericParams(typeArgs: genericArgs)
        if case .array(let element) = paramType {
            var arrayLengthParamCOMType = COMType(name: "uint32_t")
            if param.isByRef { arrayLengthParamCOMType = arrayLengthParamCOMType.addingIndirection() }
            comParams.append(.init(type: arrayLengthParamCOMType, name: param.name.map { $0 + "Length" }))

            var arrayElementsCOMType = try toCOMType(element).addingIndirection()
            if param.isByRef { arrayElementsCOMType = arrayElementsCOMType.addingIndirection() }
            comParams.append(.init(type: arrayElementsCOMType, name: param.name))
        }
        else {
            var paramCOMType = try toCOMType(paramType)
            if param.isByRef { paramCOMType = paramCOMType.addingIndirection() }
            comParams.append(.init(type: paramCOMType, name: param.name))
        }
    }
}