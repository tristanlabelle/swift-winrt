
/// A COM-exported object delegating its implementation to a Swift object.
public class ExportedDelegate<Projection: DelegateProjection>: COMPrimaryExport<Projection>, COMEmbedderWithDelegatedImplementation {
    public let closure: Projection.SwiftObject

    public init(_ closure: Projection.SwiftObject) {
        self.closure = closure
    }

    public var delegatedImplementation: AnyObject { closure as AnyObject }
}