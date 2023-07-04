import SwiftWriter

extension CAbi {
    struct SourceFileWriter {
        private let output: IndentedTextOutputStream

        init(output: some TextOutputStream) {
            self.output = .init(inner: output)

            self.output.writeLine(grouping: .never, "#pragma once")
        }

        func writeEnum(mangledName: String, enumerants: [Enumerant]) {
            let lineGrouping = output.allocateVerticalGrouping()
            output.beginLine(grouping: lineGrouping)
            output.write("typedef enum ")
            output.write(mangledName, endLine: true)
            output.writeIndentedBlock(grouping: lineGrouping, header: "{") {
                for enumerant in enumerants {
                    output.write(mangledName)
                    output.write("_")
                    output.write(enumerant.localName)
                    output.write(" = ")
                    output.write(String(enumerant.value))
                    output.write(";", endLine: true)
                }
            }
            output.beginLine(grouping: lineGrouping)
            output.write("} ")
            output.write(mangledName)
            output.write(";", endLine: true)
        }

        func writeStruct(mangledName: String, members: [DataMember]) {
            let lineGrouping = output.allocateVerticalGrouping()
            output.beginLine(grouping: lineGrouping)
            output.write("typedef struct ")
            output.write(mangledName, endLine: true)
            output.writeIndentedBlock(grouping: lineGrouping, header: "{") {
                for member in members {
                    writeType(member.type)
                    output.write(" ")
                    output.write(member.name)
                    output.write(";", endLine: true)
                }
            }
            output.beginLine(grouping: lineGrouping)
            output.write("} ")
            output.write(mangledName)
            output.write(";", endLine: true)
        }

        func writeInterface(mangledName: String, functions: [Function]) {
            writeIID(mangledName: mangledName)
            writeVTable(mangledName: mangledName, functions: functions)
            writeInterfaceWithVTable(mangledName: mangledName)
        }

        private func writeIID(mangledName: String) {
            output.beginLine(grouping: .withName("iid"))
            output.write("EXTERN_C const IID IID_")
            output.write(mangledName)
            output.write(";", endLine: true)
        }

        private func writeVTable(mangledName: String, functions: [Function]) {
            let lineGrouping = output.allocateVerticalGrouping()
            output.beginLine(grouping: lineGrouping)
            output.write("typedef struct ")
            output.write(mangledName)
            output.write(vtableSuffix, endLine: true)
            output.writeIndentedBlock(grouping: lineGrouping, header: "{") {
                output.writeLine(grouping: .never, "BEGIN_INTERFACE")

                for function in functions {
                    writeFunction(function)
                }

                output.writeLine(grouping: .never, "END_INTERFACE")
            }
            output.beginLine(grouping: lineGrouping)
            output.write("} ")
            output.write(mangledName)
            output.write(vtableSuffix)
            output.write(";", endLine: true)
        }

        private func writeFunction(_ function: Function) {
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

        private func writeInterfaceWithVTable(mangledName: String) {
            let lineGrouping = output.allocateVerticalGrouping()
            output.beginLine(grouping: lineGrouping)
            output.write("interface ")
            output.write(mangledName, endLine: true)
            output.writeIndentedBlock(grouping: lineGrouping, header: "{") {
                output.write("CONST_VTBL struct ")
                output.write(mangledName)
                output.write(vtableSuffix)
                output.write("* lpVtbl;", endLine: true)
            }
            output.beginLine(grouping: lineGrouping)
            output.write("};", endLine: true)
        }

        struct Function {
            var returnType: CType = .hresult
            var name: String
            var params: [Param]
        }

        struct Param {
            var type: CType
            var name: String?
        }

        struct DataMember {
            var type: CType
            var name: String
        }

        struct Enumerant {
            var localName: String
            var value: Int
        }
    }
}