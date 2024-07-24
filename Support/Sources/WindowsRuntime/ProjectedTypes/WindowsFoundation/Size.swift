/// Represents number values that specify a height and width.
public struct WindowsFoundation_Size: Hashable, Codable, Sendable {
    /// The width.
    public var width: Swift.Float

    /// The height.
    public var height: Swift.Float

    public init() {
        self.width = 0
        self.height = 0
    }

    public init(width: Swift.Float, height: Swift.Float) {
        self.width = width
        self.height = height
    }
}

import SWRT_WindowsFoundation

extension WindowsFoundation_Size: WindowsRuntime.StructProjection, COM.ABIInertProjection {
    public typealias SwiftValue = Self
    public typealias ABIValue = SWRT_WindowsFoundation_Size

    public static let typeName = "Windows.Foundation.Size"

    public static var ireferenceID: COM.COMInterfaceID {
        COMInterfaceID(0x61723086, 0x8E53, 0x5276, 0x9F36, 0x2A4BB93E2B75)
    }

    public static var abiDefaultValue: ABIValue { .init() }

    public static func toSwift(_ value: ABIValue) -> SwiftValue {
        .init(width: value.Width, height: value.Height)
    }

    public static func toABI(_ value: SwiftValue) -> SWRT_WindowsFoundation_Size {
        .init(Width: value.width, Height: value.height)
    }

    public static func box(_ value: SwiftValue) throws -> IInspectable {
        try IInspectableProjection.toSwift(PropertyValueStatics.createSize(value))
    }
}