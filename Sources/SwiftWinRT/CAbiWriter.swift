import SwiftWriter
import DotNetMD

struct CAbiWriter {
    private let output: IndentedTextOutputStream

    init(output: some TextOutputStream) {
        self.output = .init(inner: output)

        self.output.writeLine(grouping: .never, "#pragma once")
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
        output.write(CNameMangling.vtblSuffix, endLine: true)
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
        output.write(CNameMangling.vtblSuffix)
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
            output.write(" ")
            output.write(param.name)
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
            output.write(CNameMangling.vtblSuffix)
            output.write("* lpVtbl;", endLine: true)
        }
        output.beginLine(grouping: lineGrouping)
        output.write("};", endLine: true)
    }

    struct Function {
        var returnType: CType = .hresult
        var name: String
        var params: [Variable]
    }

    struct Variable {
        var type: CType
        var name: String
    }

    struct CType: ExpressibleByStringLiteral {
        public static let hresult = CType(name: "HRESULT")

        public static func pointer(to name: String) -> CType {
            .init(name: name, pointerIndirections: 1)
        }

        var name: String
        var pointerIndirections: Int = 0

        init(stringLiteral name: String) {
            self.name = name
        }

        init(name: String, pointerIndirections: Int = 0) {
            self.name = name
            self.pointerIndirections = pointerIndirections
        }
    }
}

extension CAbiWriter {
    func write(typeDefinition: TypeDefinition, genericArgs: [BoundType]) {
        if typeDefinition is InterfaceDefinition {
            let mangledName = CNameMangling.mangle(typeDefinition: typeDefinition, genericArgs: genericArgs)

            var functions = [Function]()
            functions.append(Function(name: "QueryInterface", params: [
                Variable(type: .pointer(to: mangledName), name: "This"),
                Variable(type: .init(name: "REFIID"), name: "riid"),
                Variable(type: .init(name: "void", pointerIndirections: 2), name: "ppvObject")
            ]))
            functions.append(Function(returnType: "ULONG", name: "AddRef", params: [
                Variable(type: .pointer(to: mangledName), name: "This")
            ]))
            functions.append(Function(returnType: "ULONG", name: "Release", params: [
                Variable(type: .pointer(to: mangledName), name: "This")
            ]))
            functions.append(Function(name: "GetIids", params: [
                Variable(type: .pointer(to: mangledName), name: "This"),
                Variable(type: .pointer(to: "ULONG"), name: "iidCount"),
                Variable(type: .init(name: "IID", pointerIndirections: 2), name: "iids")
            ]))
            functions.append(Function(name: "GetRuntimeClassName", params: [
                Variable(type: .pointer(to: mangledName), name: "This"),
                Variable(type: .pointer(to: "HSTRING"), name: "className")
            ]))
            functions.append(Function(name: "GetTrustLevel", params: [
                Variable(type: .pointer(to: mangledName), name: "This"),
                Variable(type: .pointer(to: "TrustLevel"), name: "trustLevel")
            ]))

            writeInterface(
                mangledName: mangledName,
                functions: functions)
        }
    }
}