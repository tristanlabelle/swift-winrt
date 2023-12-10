import DotNetMetadata

extension SwiftProjection {
    internal func getParamProjections(method: Method, genericTypeArgs: [TypeNode]) throws -> (params: [ParamProjection], return: ParamProjection?) {
        var params = [ParamProjection]()
        for (index, param) in try method.params.enumerated() {
            params.append(ParamProjection(
                name: param.name ?? "_param\(index)",
                typeProjection: try getTypeProjection(
                    param.type.bindGenericParams(typeArgs: genericTypeArgs)),
                passBy: param.isByRef 
                    ? .reference(in: param.isIn, out: param.isOut, optional: false)
                    : .value))
        }

        var returnParam: ParamProjection?
        if try method.hasReturnValue {
            returnParam = ParamProjection(
                name: "_result",
                typeProjection: try getTypeProjection(
                    method.returnType.bindGenericParams(typeArgs: genericTypeArgs)),
                passBy: .return)
        }
        return (params, returnParam)
    }
}