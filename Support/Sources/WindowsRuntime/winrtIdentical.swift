import COM

public func winrtIdentical(_ lhs: IInspectable, _ rhs: IInspectable) -> Bool {
    comIdentical(lhs, rhs)
}