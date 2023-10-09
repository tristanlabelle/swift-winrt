public protocol EnumProjection: Hashable, ABIInertProjection 
    where ABIValue == CEnum, SwiftValue == Self {
    associatedtype CEnum: RawRepresentable where CEnum.RawValue: FixedWidthInteger & Hashable

    var value: CEnum.RawValue { get }
    init(_ value: CEnum.RawValue)
}

extension EnumProjection {
    public init(_ value: CEnum) { self.init(value.rawValue) }
    public static func toSwift(_ value: CEnum) -> Self { Self(value) }
    public static func toABI(_ value: Self) throws -> CEnum { CEnum(rawValue: value.value)! }
}
