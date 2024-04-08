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

    public func toParameter(label: String = "_", _ param: Param, genericTypeArgs: [TypeNode] = []) throws -> SwiftParam {
        SwiftParam(label: label, name: toParamName(param), `inout`: param.isByRef,
            type: try genericTypeArgs.isEmpty ? toType(param.type) : toType(param.type.bindGenericParams(typeArgs: genericTypeArgs)))
    }

    public func getParamProjection(_ param: ParamBase, genericTypeArgs: [TypeNode] = []) throws -> ParamProjection {
        let passBy: ParamProjection.PassBy = switch param {
            case is ReturnParam: .return(nullAsError: isNullAsErrorEligible(try param.type))
            case let param as Param:
                param.isByRef
                    ? .reference(in: param.isIn, out: param.isOut, optional: false)
                    : .value
            default: fatalError("Unexpected parameter class")
        }

        return ParamProjection(
            name: toParamName(param),
            typeProjection: try getTypeProjection(
                param.type.bindGenericParams(typeArgs: genericTypeArgs)),
            passBy: passBy)
    }

    public func getParamProjections(method: Method, genericTypeArgs: [TypeNode], abiKind: ABIMethodKind? = nil) throws -> (params: [ParamProjection], return: ParamProjection?) {
        let abiKind = try abiKind ?? ABIMethodKind.forABITypeMethods(definition: method.definingType)

        var paramProjections = try method.params.map { try getParamProjection($0, genericTypeArgs: genericTypeArgs) }

        if abiKind == .composableFactory {
            // The last two parameters are the outer and inner objects,
            // which should not be projected to Swift.
            for i in paramProjections.count-2..<paramProjections.count {
                let paramProjection = paramProjections[i]
                let abiType = paramProjection.typeProjection.abiType
                paramProjections[i] = ParamProjection(
                    name: paramProjection.name,
                    typeProjection: TypeProjection(
                        abiType: abiType,
                        abiDefaultValue: .`nil`,
                        swiftType: abiType,
                        swiftDefaultValue: .`nil`,
                        projectionType: .void, // No projection needed
                        kind: .identity),
                    passBy: paramProjection.passBy)
            }
        }

        let returnProjection: ParamProjection?
        switch abiKind {
            case .activationFactory, .composableFactory:
                // Factory method. Preserve the ABI and return it as COMReference
                guard case .bound(let objectType) = try method.returnType else {
                    fatalError("ABI factory methods are expected to return a bound type.")
                }
                let abiType = try toABIType(objectType)
                returnProjection = ParamProjection(
                    name: "_result",
                    typeProjection: TypeProjection(
                        abiType: .optional(wrapped: .unsafeMutablePointer(to: abiType)),
                        abiDefaultValue: .`nil`,
                        swiftType: SupportModules.COM.comReference(to: abiType),
                        swiftDefaultValue: .`nil`, // No projection needed
                        projectionType: .void, // No projection needed
                        kind: .identity),
                    passBy: .return(nullAsError: false))

            default:
                returnProjection = try method.hasReturnValue
                    ? getParamProjection(method.returnParam, genericTypeArgs: genericTypeArgs)
                    : nil
        }

        return (params: paramProjections, return: returnProjection)
    }
}