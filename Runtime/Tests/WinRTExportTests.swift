import XCTest
import WindowsRuntime

internal final class WinRTExportTests: XCTestCase {
    func testIUnknownIdentityRule() throws {
        let swiftObject = SwiftObject()
        let unknown2 = try swiftObject.queryInterface(IUnknown2Projection.self)
        let inspectable2 = try swiftObject.queryInterface(IInspectable2Projection.self)
        XCTAssertEqual(
            try unknown2.queryInterface(IUnknownProjection.self)._unknown,
            try inspectable2.queryInterface(IUnknownProjection.self)._unknown)
    }

    func testIInspectableIdentityRule() throws {
        let swiftObject = SwiftObject()
        let unknown2 = try swiftObject.queryInterface(IUnknown2Projection.self)
        let inspectable2 = try swiftObject.queryInterface(IInspectable2Projection.self)
        XCTAssertEqual(
            try unknown2.queryInterface(IInspectableProjection.self)._unknown,
            try inspectable2.queryInterface(IInspectableProjection.self)._unknown)
    }

    func testQueryInterfaceTransitivityRule() throws {
        let swiftObject = SwiftObject()
        let unknown = try swiftObject.queryInterface(IUnknownProjection.self)
        let inspectable = try swiftObject.queryInterface(IInspectableProjection.self)
        let unknown2 = try swiftObject.queryInterface(IUnknown2Projection.self)
        let inspectable2 = try swiftObject.queryInterface(IInspectable2Projection.self)

        // QueryInterface should succeed from/to any pair of implemented interfaces
        let objects: [any IUnknownProtocol] = [unknown, inspectable, unknown2, inspectable2]
        for object in objects {
            _ = try object.queryInterface(IUnknownProjection.self)
            _ = try object.queryInterface(IInspectableProjection.self)
            _ = try object.queryInterface(IUnknown2Projection.self)
            _ = try object.queryInterface(IInspectable2Projection.self)
        }
    }

    func testRoundTripToOriginalSwiftObject() throws {
        XCTFail("TODO: Test that sending a Swift object to WinRT and back returns the original Swift object")
    }
}