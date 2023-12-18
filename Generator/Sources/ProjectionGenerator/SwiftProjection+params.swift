import CodeWriters
import DotNetMetadata

extension SwiftProjection {
    internal func toParamName(_ param: ParamBase) -> String {
        switch param {
            case is ReturnParam: "_result"
            case let param as Param: param.name ?? "_param\(param.index)"
            default: fatalError("Unexpected parameter class")
        }
    }

    func toParameter(label: String = "_", _ param: Param, genericTypeArgs: [TypeNode] = []) throws -> SwiftParam {
        SwiftParam(label: label, name: toParamName(param), `inout`: param.isByRef,
            type: try genericTypeArgs.isEmpty ? toType(param.type) : toType(param.type.bindGenericParams(typeArgs: genericTypeArgs)))
    }

    internal func getParamProjection(_ param: ParamBase, genericTypeArgs: [TypeNode] = []) throws -> ParamProjection {
        let passBy: ParamProjection.PassBy = switch param {
            case is ReturnParam: .return
            case let param as Param:
                param.isByRef
                    ? .reference(in: param.isIn, out: param.isOut, optional: false)
                    : .value
            default: fatalError("Unexpected parameter class")
        }

        return ParamProjection(
            name: toParamName(param),
            typeProjection: try getTypeProjection(
                try param.type.bindGenericParams(typeArgs: genericTypeArgs)
            ),
            passBy: passBy)
    }

    internal func getParamProjections(method: Method, genericTypeArgs: [TypeNode]) throws -> (params: [ParamProjection], return: ParamProjection?) {
        return (
            params: try method.params.map { try getParamProjection($0, genericTypeArgs: genericTypeArgs) },
            return: try method.hasReturnValue
                ? getParamProjection(method.returnParam, genericTypeArgs: genericTypeArgs)
                : nil)
    }
}