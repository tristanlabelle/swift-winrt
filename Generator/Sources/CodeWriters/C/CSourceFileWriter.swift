public class CSourceFileWriter {
    public let output: LineBasedTextOutputStream

    public init(output: some TextOutputStream, pragmaOnce: Bool = true) {
        self.output = .init(inner: output)
        if pragmaOnce {
            self.output.writeFullLine(group: .alone, "#pragma once")
        }
    }

    public enum IncludeKind { case doubleQuotes; case angleBrackets }

    public func writeInclude(pathSpec: String, kind: IncludeKind) {
        output.beginLine(group: .named("include"))
        switch kind {
            case .doubleQuotes: output.write("#include \"\(pathSpec)\"", endLine: true)
            case .angleBrackets: output.write("#include <\(pathSpec)>", endLine: true)
        }
    }

    public func writeForwardDecl(comment: String? = nil, typedef: Bool = false, kind: CTypeDeclKind, name: String) {
        if let comment { output.writeFullLine(group: .named("forwardDecl"), "// \(comment)") }
        output.beginLine(group: .named("forwardDecl"))
        if typedef { output.write("typedef ") }
        switch kind {
            case .struct: output.write("struct ")
            case .enum: output.write("enum ")
            case .union: output.write("union ")
        }
        output.write(name)
        if typedef {
            output.write(" ")
            output.write(name)
        }
        output.write(";", endLine: true)
    }

    public func writeTypedef(comment: String? = nil, type: CType, name: String) {
        if let comment { output.writeFullLine(group: .named("typedef"), "// \(comment)") }
        output.beginLine(group: .named("typedef"))
        output.write("typedef ")
        if !writeType(type, variableName: name) {
            output.write(" ")
            output.write(name)
        }
        output.write(";", endLine: true)
    }

    public func writeEnum(comment: String? = nil, typedef: Bool = false, name: String, enumerants: [CEnumerant], enumerantPrefix: String? = nil) {
        let lineGrouping = output.createLineGroup()

        if let comment { output.writeFullLine(group: lineGrouping, "// \(comment)") }

        output.beginLine(group: lineGrouping)
        if typedef { output.write("typedef ") }
        output.write("enum ")
        output.write(name, endLine: true)
        output.writeLineBlock(group: lineGrouping, header: "{") {
            for (index, enumerant) in enumerants.enumerated() {
                if let enumerantPrefix { output.write(enumerantPrefix) }
                output.write(enumerant.name)
                if let value = enumerant.value {
                    output.write(" = ")
                    output.write(String(value))
                }
                if index < enumerants.count - 1 { output.write(",") }
                output.endLine()
            }
        }
        output.beginLine(group: lineGrouping)
        output.write("}")
        if typedef {
            output.write(" ")
            output.write(name)
        }
        output.write(";", endLine: true)
    }

    public func writeStruct(comment: String? = nil, typedef: Bool = false, name: String, members: [CVariableDecl]) {
        let lineGrouping = output.createLineGroup()

        if let comment { output.writeFullLine(group: lineGrouping, "// \(comment)") }

        output.beginLine(group: lineGrouping)
        if typedef { output.write("typedef ") }
        output.write("struct ")
        output.write(name, endLine: true)
        output.writeLineBlock(group: lineGrouping, header: "{") {
            for member in members {
                writeVariableDecl(member)
            }
        }
        output.beginLine(group: lineGrouping)
        output.write("}")
        if typedef {
            output.write(" ")
            output.write(name)
        }
        output.write(";", endLine: true)
    }

    private func writeVariableDecl(_ member: CVariableDecl) {
        output.beginLine(group: .named("variableDecl"))
        if !writeType(member.type, variableName: member.name) {
            output.write(" ")
            output.write(member.name)
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
        if case let .pointer(pointee, nullability) = type.specifier {
            writeQualifiersAndPointers(pointee, name: name)
            output.write("*")
            writeQualifiers(type, prefix: false)
            if let nullability {
                switch nullability {
                    case .nonnull: output.write(" _Nonnull")
                    case .nullable: output.write(" _Nullable")
                    case .unspecified: break
                }
            }
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
            case .pointer(let pointee, _): return getLeafTypeSpecifier(pointee)
            default: return type.specifier
        }
    }
}