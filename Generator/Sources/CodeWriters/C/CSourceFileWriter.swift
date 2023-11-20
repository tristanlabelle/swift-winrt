public struct CSourceFileWriter {
    private let output: IndentedTextOutputStream

    public init(output: some TextOutputStream, pragmaOnce: Bool = true) {
        self.output = .init(inner: output)
        if pragmaOnce {
            self.output.writeLine(grouping: .never, "#pragma once")
        }
    }

    public func writeInclude(header: String, local: Bool) {
        output.beginLine(grouping: .withName("include"))
        output.write(local ? "#include \"\(header)\"" : "#include <\(header)>", endLine: true)
    }

    public func writeForwardDeclaration(kind: CTypeDeclKind, name: String) {
        output.beginLine(grouping: .withName("forwardDecl"))
        switch kind {
            case .struct: output.write("struct ")
            case .enum: output.write("enum ")
            case .union: output.write("union ")
        }
        output.write(name)
        output.write(";", endLine: true)
    }

    public func writeEnum(name: String, enumerants: [CEnumerant], enumerantPrefix: String? = nil, typedef: Bool = true) {
        let lineGrouping = output.allocateVerticalGrouping()
        output.beginLine(grouping: lineGrouping)
        if typedef { output.write("typedef ") }
        output.write("enum ")
        output.write(name, endLine: true)
        output.writeIndentedBlock(grouping: lineGrouping, header: "{") {
            for (index, enumerant) in enumerants.enumerated() {
                if let enumerantPrefix { output.write(enumerantPrefix) }
                output.write(enumerant.name)
                output.write(" = ")
                output.write(String(enumerant.value))
                if index < enumerants.count - 1 { output.write(",") }
                output.endLine()
            }
        }
        output.beginLine(grouping: lineGrouping)
        output.write("}")
        if typedef {
            output.write(" ")
            output.write(name)
        }
        output.write(";", endLine: true)
    }

    public func writeStruct(name: String, members: [CVariableDecl], typedef: Bool = true) {
        let lineGrouping = output.allocateVerticalGrouping()
        output.beginLine(grouping: lineGrouping)
        if typedef { output.write("typedef ") }
        output.write("struct ")
        output.write(name, endLine: true)
        output.writeIndentedBlock(grouping: lineGrouping, header: "{") {
            for member in members {
                writeVariableDecl(member)
            }
        }
        output.beginLine(grouping: lineGrouping)
        output.write("}")
        if typedef {
            output.write(" ")
            output.write(name)
        }
        output.write(";", endLine: true)
    }

    private func writeVariableDecl(_ member: CVariableDecl) {
        output.beginLine(grouping: .withName("variableDecl"))
        if !writeType(member.type, variableName: member.name), let memberName = member.name {
            output.write(" ")
            output.write(memberName)
        }
        output.write(";", endLine: true)
    }

    private func writeType(_ type: CType, variableName: String? = nil) -> Bool {
        // The syntax is quite different for a type reference and a function pointer
        switch Self.getLeafTypeSpecifier(type) {
            case let .reference(kind, name):
                if let kind = kind {
                    output.write(kind.keyword)
                    output.write(" ")
                }
                writeQualifiersAndPointers(type, name: name)
                return false // We didn't write the variable name, it should be written as a suffix

            case let .functionPointer(`return`, callingConvention, params):
                _ = writeType(`return`)

                output.write(" (")
                if let callingConvention {
                    output.write(callingConvention.keyword)
                    output.write(" ")
                }
                output.write("*")
                writeQualifiersAndPointers(type, name: variableName)
                output.write(")")

                output.write("(")
                for (paramIndex, param) in params.enumerated() {
                    if paramIndex > 0 { output.write(", ") }
                    if !writeType(param.type, variableName: param.name), let paramName = param.name {
                        output.write(" ")
                        output.write(paramName)
                    }
                }
                output.write(")")
                return true // We did write the variable name

            case let specifier:
                fatalError("Unexpected leaf C type specifier: \(specifier)")
        }
    }

    private func writeQualifiersAndPointers(_ type: CType, name: String?) {
        if case let .pointer(pointee) = type.specifier {
            writeQualifiersAndPointers(pointee, name: name)
            output.write("*")
            writeQualifiers(type, prefix: false)
        } else {
            writeQualifiers(type, prefix: true)
            if let name { output.write(name) }
        }
    }

    private func writeQualifiers(_ type: CType, prefix: Bool) {
        if type.const {
            output.write(prefix ? "const ": " const")
        }
        if type.volatile {
            output.write(prefix ? "volatile ": " volatile")
        }
    }

    private static func getLeafTypeSpecifier(_ type: CType) -> CTypeSpecifier {
        switch type.specifier {
            case .pointer(let pointee): return getLeafTypeSpecifier(pointee)
            default: return type.specifier
        }
    }
}