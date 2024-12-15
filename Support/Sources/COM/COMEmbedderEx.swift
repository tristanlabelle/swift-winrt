
/// Base class for Swift objects embedding COM interfaces,
/// but which do not directly provide their implementation.
/// 
/// This is a base class and not a protocol for faster upcasting.
open class COMEmbedderEx {
    public let implementer: AnyObject

    // Either of self or implementer must provide the IUnknown implementation.
    internal var unknown: IUnknown { (self as? IUnknown) ?? (implementer as! IUnknown) }

    public init(implementer: IUnknown) {
        self.implementer = implementer
    }

    public init(implementer: AnyObject) {
        self.implementer = implementer
        assert(self is IUnknown || implementer is IUnknown)
    }
}