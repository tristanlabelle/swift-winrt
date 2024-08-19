public func comIdentical(_ lhs: IUnknown, _ rhs: IUnknown) -> Bool {
    guard let lhsIdentityReference = try? lhs._queryInterface(IUnknownProjection.interfaceID) else { return false }
    guard let rhsIdentityReference = try? rhs._queryInterface(IUnknownProjection.interfaceID) else { return false }
    return lhsIdentityReference.pointer == rhsIdentityReference.pointer
}