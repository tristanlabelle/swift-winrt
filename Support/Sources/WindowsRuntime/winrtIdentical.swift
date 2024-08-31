import COM

/// Determines whether two WinRT references are implemented by the same underlying object.
public func winrtIdentical(_ lhs: IInspectable, _ rhs: IInspectable) -> Bool {
    comIdentical(lhs, rhs)
}