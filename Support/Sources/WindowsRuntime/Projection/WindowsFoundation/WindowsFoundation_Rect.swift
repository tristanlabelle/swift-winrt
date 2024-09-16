/// Contains number values that represent the location and size of a rectangle.
public struct WindowsFoundation_Rect: Hashable, Codable, Sendable {
    /// The x-coordinate of the upper-left corner of the rectangle.
    public var x: Swift.Float

    /// The y-coordinate of the upper-left corner of the rectangle.
    public var y: Swift.Float

    /// The width of the rectangle, in pixels.
    public var width: Swift.Float

    /// The height of the rectangle, in pixels.
    public var height: Swift.Float

    public init() {
        self.x = 0
        self.y = 0
        self.width = 0
        self.height = 0
    }

    public init(x: Swift.Float, y: Swift.Float, width: Swift.Float, height: Swift.Float) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

import SWRT_WindowsFoundation

extension WindowsFoundation_Rect: WindowsRuntime.StructBinding, COM.PODBinding {
    public typealias SwiftValue = Self
    public typealias ABIValue = SWRT_WindowsFoundation_Rect

    public static let typeName = "Windows.Foundation.Rect"

    public static var ireferenceID: COM.COMInterfaceID {
        COMInterfaceID(0x80423F11, 0x054F, 0x5EAC, 0xAFD3, 0x63B6CE15E77B)
    }

    public static var ireferenceArrayID: COM.COMInterfaceID {
        COMInterfaceID(0x8A444256, 0xD661, 0x5E9A, 0xA72B, 0xD8F1D7962D0C)
    }

    public static var abiDefaultValue: ABIValue { .init() }

    public static func toSwift(_ value: ABIValue) -> SwiftValue {
        .init(x: value.X, y: value.Y, width: value.Width, height: value.Height)
    }

    public static func toABI(_ value: SwiftValue) -> ABIValue {
        .init(X: value.x, Y: value.y, Width: value.width, Height: value.height)
    }

    public static func createIReference(_ value: SwiftValue) throws -> WindowsFoundation_IReference<SwiftValue> {
        try PropertyValueStatics.createIReference(value, valueBinding: Self.self, factory: PropertyValueStatics.createRect)
    }

    public static func createIReferenceArray(_ value: [SwiftValue]) throws -> WindowsFoundation_IReferenceArray<SwiftValue> {
        try PropertyValueStatics.createIReferenceArray(value, valueBinding: Self.self, factory: PropertyValueStatics.createRectArray)
    }
}