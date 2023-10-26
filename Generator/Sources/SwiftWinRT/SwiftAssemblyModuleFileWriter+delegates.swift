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
            try writeDelegateProjection(delegateDefinition.bind(),
                projectionName: projection.toProjectionTypeName(delegateDefinition),
                to: sourceFileWriter)
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
                try writeDelegateProjection(delegateDefinition.bind(genericArgs: genericArgs),
                    projectionName: "Projection",
                    to: sourceFileWriter)
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

    fileprivate func writeDelegateProjection(
            _ delegate: BoundDelegate, projectionName: String,
            to writer: some SwiftTypeDeclarationWriter) throws {

        // internal final class Instance: WinRTDelegateProjectionBase<Instance>, COMTwoWayProjection {
        //     public typealias SwiftValue = WindowsFoundation_TypedEventHandler<TSender, TResult>
        //     public typealias CStruct = CWinRT.__FITypedEventHandler_2_Windows__CFoundation__CIMemoryBufferReference_IInspectable
        //     public typealias CVTableStruct = CWinRT.__FITypedEventHandler_2_Windows__CFoundation__CIMemoryBufferReference_IInspectableVtbl

        //     public static let iid = IID(0xF4637D4A, 0x0760, 0x5431, 0xBFC0, 0x24EB1D4F6C4F)
        //     public static var vtable: CVTablePointer { withUnsafePointer(to: &vtableStruct) { $0 } }
        //     private static var vtableStruct: CVTableStruct = .init(
        //         QueryInterface: { this, iid, ppvObject in _queryInterface(this, iid, ppvObject) },
        //         AddRef: { this in _addRef(this) },
        //         Release: { this in _release(this) },
        //         Invoke: { this, sender, args in _implement(this) { handler in
        //             let sender = WindowsFoundation_IMemoryBufferReferenceProjection.toSwift(copying: sender)
        //             let args = WindowsRuntime.IInspectableProjection.toSwift(copying: args)
        //             try handler(sender, args)
        //         } }
        //     )
        // }

        try writer.writeClass(
                visibility: SwiftProjection.toVisibility(delegate.definition.visibility),
                final: true, name: projectionName,
                base: .identifier("WinRTDelegateProjectionBase", genericArgs: [.identifier(projectionName)]),
                protocolConformances: [.identifier("COMTwoWayProjection")]) { writer throws in 

            try writeWinRTProjectionConformance(interfaceOrDelegate: delegate.asBoundType, to: writer)

            // public var swiftObject: Projection.SwiftObject { invoke }
            writer.writeComputedProperty(
                visibility: .public, override: true, name: "swiftObject",
                type: .identifier("SwiftObject"),
                get: { $0.writeStatement("invoke") })

            // The only member should be an "invoke()" method
            try writeMemberImplementations(interfaceOrDelegate: delegate.asBoundType, static: false, thisName: "comPointer", to: writer)

            // public static var vtable: COMVirtualTablePointer { withUnsafePointer(to: &vtableStruct) { $0 } }
            // TODO: Actually generate a virtual table struct
            writer.writeComputedProperty(visibility: .public, static: true, name: "vtable",
                type: .identifier("COMVirtualTablePointer"), throws: false,
                get: { $0.writeNotImplemented() })
        }
    }
}