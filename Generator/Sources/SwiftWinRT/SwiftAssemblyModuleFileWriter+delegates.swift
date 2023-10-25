import CodeWriters
import DotNetMetadata

extension SwiftAssemblyModuleFileWriter {
    internal func writeDelegate(_ delegateDefinition: DelegateDefinition) throws {
        try sourceFileWriter.writeTypeAlias(
            visibility: SwiftProjection.toVisibility(delegateDefinition.visibility),
            name: try projection.toTypeName(delegateDefinition),
            typeParameters: delegateDefinition.genericParams.map { $0.name },
            target: .function(
                params: delegateDefinition.invokeMethod.params.map { try projection.toType($0.type) },
                throws: true,
                returnType: projection.toReturnType(delegateDefinition.invokeMethod.returnType)
            )
        )
    }

    internal func writeDelegateProjection(_ delegateDefinition: DelegateDefinition, genericArgs: [TypeNode]?) throws {
        if delegateDefinition.genericArity == 0 {
            // class AsyncActionCompletedHandlerProjection: WinRTProjection... {}
            // Not implemented
        }
        else if let genericArgs {
            // extension AsyncOperationCompletedHandlerProjection where T == Bool {
            //     internal final class Projection: WinRTProjection... {}
            // }
            let whereClauses = try delegateDefinition.genericParams.map {
                try "\($0.name) == \(projection.toType(genericArgs[$0.index]))"
            }
            try sourceFileWriter.writeExtension(
                    name: projection.toProjectionTypeName(delegateDefinition),
                    whereClauses: whereClauses) { writer in
                // Not implemented
            }
        }
        else {
            // public enum AsyncOperationCompletedHandlerProjection<T> {}
            try sourceFileWriter.writeEnum(
                visibility: SwiftProjection.toVisibility(delegateDefinition.visibility),
                name: projection.toProjectionTypeName(delegateDefinition),
                typeParameters: delegateDefinition.genericParams.map { $0.name }) { _ in }
        }
    }
}