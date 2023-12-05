import CodeWriters
import DotNetMetadata
import WindowsMetadata

extension SwiftAssemblyModuleFileWriter {
    func writeVirtualTable(interfaceOrDelegate: BoundType, to output: IndentedTextOutputStream) throws {
        try output.writeIndentedBlock(header: "COMVirtualTable(", footer: ")") {
            // IUnknown methods
            output.writeFullLine("QueryInterface: { this, iid, ppvObject in _queryInterface(this, iid, ppvObject) },")
            output.writeFullLine("AddRef: { this in _addRef(this) },")
            output.write("Release: { this in _release(this) }")

            // IInspectable methods (except for delegates)
            if interfaceOrDelegate.definition is InterfaceDefinition {
                output.write(",", endLine: true)
                output.writeFullLine("GetIids: { this, iidCount, iids in _getIids(this, iidCount, iids) },")
                output.writeFullLine("GetRuntimeClassName: { this, className in _getRuntimeClassName(this, className) },")
                output.write("GetTrustLevel: { this, trustLevel in _getTrustLevel(this, trustLevel) }")
            }

            // Custom interface/delegate methods
            for method in interfaceOrDelegate.definition.methods {
                output.write(",", endLine: true)
                try writeVirtualTableFunc(method, genericTypeArgs: interfaceOrDelegate.genericArgs, to: output)
            }
        }
    }

    fileprivate func writeVirtualTableFunc(_ method: Method, genericTypeArgs: [TypeNode], to output: IndentedTextOutputStream) throws {
        // Special case for getters
        if try method.params.count == 0 && method.hasReturnValue {
            return try writeVirtualTableGetter(method, genericTypeArgs: genericTypeArgs, to: output)
        }

        try writeVirtualTableFuncImplementation(
                name: method.findAttribute(OverloadAttribute.self) ?? method.name,
                paramNames: method.params.map { $0.name! },
                to: output) {
            // Declare Swift values for out params
            // Invoke the Swift implementation
            // Convert out params to the ABI representation
            output.writeFullLine("fatalError(\"Not implemented: \\(#function)\")")
        }
    }

    fileprivate func writeVirtualTableGetter(_ method: Method, genericTypeArgs: [TypeNode], to output: IndentedTextOutputStream) throws {
        let memberInvocation: String
        if case .special = method.nameKind, method.name.hasPrefix("get_") {
            let propertyName = method.name[method.name.index(method.name.startIndex, offsetBy: 4)...]
            memberInvocation = Casing.pascalToCamel(String(propertyName))
        } else {
            let methodName = projection.toMemberName(method)
            memberInvocation = "\(methodName)()"
        }

        let returnTypeProjection = try projection.getTypeProjection(
            method.returnType.bindGenericParams(typeArgs: genericTypeArgs))
        let abiName = try method.findAttribute(OverloadAttribute.self) ?? method.name
        output.write("\(abiName): { this, result in _getter(this, result) { "
            + "try \(returnTypeProjection.projectionType).toABI($0.\(memberInvocation)) } },")
    }

    fileprivate func writeVirtualTableFuncImplementation(name: String, paramNames: [String], to output: IndentedTextOutputStream, body: () throws -> Void) rethrows {
        output.write(name)
        output.write(": ")
        output.write("{ this")
        for paramName in paramNames {
            output.write(", \(paramName)")
        }
        try output.writeIndentedBlock(header: " in _implement(this) { this in", body: body)
        output.write("} }")
    }
}