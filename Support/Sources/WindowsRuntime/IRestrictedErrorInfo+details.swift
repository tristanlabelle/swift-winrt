public struct RestrictedErrorInfoDetails {
    public var description: String? = nil
    public var error: HResult = .ok
    public var restrictedDescription: String? = nil
    public var capabilitySid: String? = nil

    public init() {}
}

extension IRestrictedErrorInfoProtocol {
    public var details: RestrictedErrorInfoDetails { get throws {
        var details = RestrictedErrorInfoDetails()
        try getErrorDetails(
            description: &details.description,
            error: &details.error,
            restrictedDescription: &details.restrictedDescription,
            capabilitySid: &details.capabilitySid)
        return details
    } }
}