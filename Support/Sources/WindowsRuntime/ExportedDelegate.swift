
/// A COM-exported object delegating its implementation to a Swift object.
public class ExportedDelegate<Binding: DelegateBinding>: COMExport<Binding>, COMEmbedderWithDelegatedImplementation {
    public let closure: Binding.SwiftObject

    public init(_ closure: Binding.SwiftObject) {
        self.closure = closure
    }

    public var delegatedImplementation: AnyObject { closure as AnyObject }
}