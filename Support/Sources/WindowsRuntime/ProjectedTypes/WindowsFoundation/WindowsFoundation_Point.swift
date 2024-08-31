/// Represents x- and y-coordinate values that define a point in a two-dimensional plane.
public struct WindowsFoundation_Point: Hashable, Codable, Sendable {
    /// The horizontal position of the point.
    public var x: Swift.Float

    /// The vertical position of the point.
    public var y: Swift.Float

    public init() {
        self.x = 0
        self.y = 0
    }

    public init(x: Swift.Float, y: Swift.Float) {
        self.x = x
        self.y = y
    }
}

import SWRT_WindowsFoundation

extension WindowsFoundation_Point: WindowsRuntime.StructProjection, COM.ABIInertProjection {
    public typealias SwiftValue = Self
    public typealias ABIValue = SWRT_WindowsFoundation_Point

    public static let typeName = "Windows.Foundation.Point"

    public static var ireferenceID: COM.COMInterfaceID {
        COMInterfaceID(0x84F14C22, 0xA00A, 0x5272, 0x8D3D, 0x82112E66DF00)
    }

    public static var ireferenceArrayID: COM.COMInterfaceID {
        COMInterfaceID(0x39313214, 0x5C7D, 0x599D, 0xAE5A, 0x17D9D6492258)
    }

    public static var abiDefaultValue: ABIValue { .init() }

    public static func toSwift(_ value: ABIValue) -> SwiftValue {
        .init(x: value.X, y: value.Y)
    }

    public static func toABI(_ value: SwiftValue) -> ABIValue {
        .init(X: value.x, Y: value.y)
    }

    public static func createIReference(_ value: SwiftValue) throws -> WindowsFoundation_IReference<SwiftValue> {
        try PropertyValueStatics.createIReference(value, projection: Self.self, factory: PropertyValueStatics.createPoint)
    }

    public static func createIReferenceArray(_ value: [SwiftValue]) throws -> WindowsFoundation_IReferenceArray<SwiftValue> {
        try PropertyValueStatics.createIReferenceArray(value, projection: Self.self, factory: PropertyValueStatics.createPointArray)
    }
}