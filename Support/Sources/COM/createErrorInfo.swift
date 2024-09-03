import COM_ABI

/// Creates an instance of `ICreateErrorInfo`.
public func createErrorInfo() throws -> ICreateErrorInfo {
    var createErrorInfo = ICreateErrorInfoProjection.abiDefaultValue
    defer { ICreateErrorInfoProjection.release(&createErrorInfo) }
    try COMError.fromABI(SWRT_CreateErrorInfo(&createErrorInfo))
    return try NullResult.unwrap(ICreateErrorInfoProjection.toSwift(createErrorInfo))
}

/// Creates an instance of `IErrorInfo` with prepopulated fields.
public func createErrorInfo(guid: GUID? = nil, source: String? = nil, description: String?,
        helpFile: String? = nil, helpContext: UInt32? = nil) throws -> IErrorInfo {
    let errorInfo = try createErrorInfo()
    if let guid { try errorInfo.setGUID(guid) }
    if let source { try errorInfo.setSource(source) }
    if let description { try errorInfo.setDescription(description) }
    if let helpFile { try errorInfo.setHelpFile(helpFile) }
    if let helpContext { try errorInfo.setHelpContext(helpContext) }
    return try errorInfo.queryInterface(IErrorInfoProjection.self)
}