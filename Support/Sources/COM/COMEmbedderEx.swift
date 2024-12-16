
/// Base class for Swift objects embedding COM interfaces,
/// which need tight control on which object implements
/// AddRef, Release, QueryInterface and other COM methods.
/// 
/// This is a base class and not a protocol for faster upcasting.
open class COMEmbedderEx {
    public init() {}

    /// Gets the object whose reference count gets modified by AddRef/Release.
    open var refCountee: AnyObject { self }

    /// Gets the object that implements QueryInterface.
    var unknown: IUnknown { (self as? IUnknown) ?? (implementer as! IUnknown) }

    /// Gets the object that implements embedded COM interfaces.
    open var implementer: AnyObject { self }
}