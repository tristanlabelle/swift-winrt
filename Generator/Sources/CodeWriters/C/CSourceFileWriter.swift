public struct CSourceFileWriter {
    private let output: IndentedTextOutputStream

    public enum TypeKind {
        case `struct`
        case `enum`
    }

    public init(output: some TextOutputStream) {
        self.output = .init(inner: output)
        self.output.writeLine(grouping: .never, "#pragma once")
    }

    public func writeInclude(header: String, local: Bool) {
        output.beginLine(grouping: .withName("include"))
        output.write(local ? "#include \"\(header)\"" : "#include <\(header)>", endLine: true)
    }

    public func writeForwardDeclaration(kind: TypeKind, name: String) {
        output.beginLine(grouping: .withName("forwardDecl"))
        switch kind {
            case .struct: output.write("struct ")
            case .enum: output.write("enum ")
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

    public func writeStruct(name: String, members: [CDataMember], typedef: Bool = true) {
        let lineGrouping = output.allocateVerticalGrouping()
        output.beginLine(grouping: lineGrouping)
        if typedef { output.write("typedef ") }
        output.write("struct ")
        output.write(name, endLine: true)
        output.writeIndentedBlock(grouping: lineGrouping, header: "{") {
            for member in members {
                writeType(member.type)
                output.write(" ")
                output.write(member.name)
                output.write(";", endLine: true)
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

    public func writeCOMInterface(name: String, functions: [CFunctionSignature], idName: String, vtableName: String) {
        writeCOMInterfaceID(name: idName)
        writeCOMVirtualTable(name: vtableName, functions: functions)
        writeCOMInterfaceStruct(name: name, vtableName: vtableName)
    }

    private func writeCOMInterfaceID(name: String) {
        output.beginLine(grouping: .withName("iid"))
        output.write("EXTERN_C const IID IID_")
        output.write(name)
        output.write(";", endLine: true)
    }

    private func writeCOMVirtualTable(name: String, functions: [CFunctionSignature]) {
        let lineGrouping = output.allocateVerticalGrouping()
        output.beginLine(grouping: lineGrouping)
        output.write("typedef struct ")
        output.write(name, endLine: true)
        output.writeIndentedBlock(grouping: lineGrouping, header: "{") {
            output.writeLine(grouping: .never, "BEGIN_INTERFACE")

            for function in functions {
                writeCOMInterfaceFunction(function)
            }

            output.writeLine(grouping: .never, "END_INTERFACE")
        }
        output.beginLine(grouping: lineGrouping)
        output.write("} ")
        output.write(name)
        output.write(";", endLine: true)
    }

    private func writeCOMInterfaceFunction(_ function: CFunctionSignature) {
        writeType(function.returnType)
        output.write(" (STDMETHODCALLTYPE* ")
        output.write(function.name)
        output.write(")(")

        for (paramIndex, param) in function.params.enumerated() {
            if paramIndex > 0 {
                output.write(", ")
            }

            writeType(param.type)
            if let paramName = param.name {
                output.write(" ")
                output.write(paramName)
            }
        }

        output.write(");", endLine: true)
    }

    private func writeCOMInterfaceStruct(name: String, vtableName: String) {
        let lineGrouping = output.allocateVerticalGrouping()
        output.beginLine(grouping: lineGrouping)
        output.write("interface ")
        output.write(name, endLine: true)
        output.writeIndentedBlock(grouping: lineGrouping, header: "{") {
            output.write("CONST_VTBL struct ")
            output.write(vtableName)
            output.write("* lpVtbl;", endLine: true)
        }
        output.beginLine(grouping: lineGrouping)
        output.write("};", endLine: true)
    }

    private func writeType(_ type: CType) {
        output.write(type.name)
        for _ in 0..<type.pointerIndirections {
            output.write("*")
        }
    }
}