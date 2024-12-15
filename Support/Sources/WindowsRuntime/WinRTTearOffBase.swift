import COM

/// Base class for COM tear-off objects for interfaces derived from IInspectable.
open class WinRTTearOffBase<Binding: InterfaceBinding>: COMTearOffBase<Binding>, IInspectableProtocol {
    public init(owner: IInspectable) {
        super.init(owner: owner)
    }

    // Delegate to the identity object, though we should be using that object's IInspectable implementation in the first place.
    public func getIids() throws -> [COMInterfaceID] { try (owner as! IInspectable).getIids() }
    public func getRuntimeClassName() throws -> String { try (owner as! IInspectable).getRuntimeClassName() }
    public func getTrustLevel() throws -> TrustLevel { try (owner as! IInspectable).getTrustLevel() }
}
