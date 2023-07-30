public struct CAbiSourceFileWriter {
    private let output: IndentedTextOutputStream

    public init(output: some TextOutputStream) {
        self.output = .init(inner: output)
        self.output.writeLine(grouping: .never, "#pragma once")
    }

    public func writeEnum(name: String, enumerants: [CEnumerant], enumerantPrefix: String? = nil, typedef: Bool = true) {
        let lineGrouping = output.allocateVerticalGrouping()
        output.beginLine(grouping: lineGrouping)
        if typedef { output.write("typedef ") }
        output.write("enum ")
        output.write(name, endLine: true)
        output.writeIndentedBlock(grouping: lineGrouping, header: "{") {
            for enumerant in enumerants {
                if let enumerantPrefix {
                    output.write(enumerantPrefix)
                }
                output.write(enumerant.name)
                output.write(" = ")
                output.write(String(enumerant.value))
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

    public func writeCOMInterface(name: String, functions: [CFunctionSignature], iidName: String, vtableName: String) {
        writeIID(name: iidName)
        writeVTable(name: vtableName, functions: functions)
        writeInterfaceWithVTable(name: name, vtableName: vtableName)
    }

    private func writeIID(name: String) {
        output.beginLine(grouping: .withName("iid"))
        output.write("EXTERN_C const IID IID_")
        output.write(name)
        output.write(";", endLine: true)
    }

    private func writeVTable(name: String, functions: [CFunctionSignature]) {
        let lineGrouping = output.allocateVerticalGrouping()
        output.beginLine(grouping: lineGrouping)
        output.write("typedef struct ")
        output.write(name, endLine: true)
        output.writeIndentedBlock(grouping: lineGrouping, header: "{") {
            output.writeLine(grouping: .never, "BEGIN_INTERFACE")

            for function in functions {
                writeFunction(function)
            }

            output.writeLine(grouping: .never, "END_INTERFACE")
        }
        output.beginLine(grouping: lineGrouping)
        output.write("} ")
        output.write(name)
        output.write(";", endLine: true)
    }

    private func writeFunction(_ function: CFunctionSignature) {
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

    private func writeType(_ type: CType) {
        output.write(type.name)
        for _ in 0..<type.pointerIndirections {
            output.write("*")
        }
    }

    private func writeInterfaceWithVTable(name: String, vtableName: String) {
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
}