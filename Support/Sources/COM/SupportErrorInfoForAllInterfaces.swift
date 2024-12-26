/// An implementation of ISupportErrorInfo which reports that all interfaces support error info.
public final class SupportErrorInfoForAllInterfaces: COMTearOffBase<ISupportErrorInfoBinding>, ISupportErrorInfoProtocol {
    public func interfaceSupportsErrorInfo(_ riid: COMInterfaceID) throws {
        // Never throw. By virtue of projection, all interfaces report their errors through IErrorInfo.
    }
}
