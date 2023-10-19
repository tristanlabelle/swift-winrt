public protocol EnumProjection: RawRepresentable, ABIInertProjection 
    where ABIValue == CEnum, SwiftValue == Self, RawValue: FixedWidthInteger & Hashable {
    associatedtype CEnum: RawRepresentable where CEnum.RawValue == RawValue

    init(rawValue value: RawValue)
}

extension EnumProjection {
    public init(_ value: CEnum) { self.init(rawValue: value.rawValue) }
    public static var abiDefaultValue: ABIValue { CEnum(rawValue: CEnum.RawValue.zero)! }
    public static func toSwift(_ value: CEnum) -> Self { Self(value) }
    public static func toABI(_ value: Self) throws -> CEnum { CEnum(rawValue: value.rawValue)! }
}
