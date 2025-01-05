import WindowsRuntime
import WinRTComponent
import XCTest

extension IInspectableProtocol {
    fileprivate func unbox<Binding: IReferenceableBinding>(_: Binding.Type) throws -> Binding.SwiftValue {
        let ireference = try self.queryInterface(WindowsFoundation_IReferenceBinding<Binding>.self)
        return try ireference.value
    }
}

class InspectableBoxingTests: WinRTTestCase {
    func testPODPrimitiveRoundTrip() throws {
        let original = Int32(42)
        XCTAssertEqual(try InspectableBoxing.boxInt32(original).unbox(Int32Binding.self), original)
        XCTAssertEqual(try InspectableBoxing.unboxInt32(createIReference(original)), original)
    }

    func testAllocatingPrimitiveRoundTrip() throws {
        let original = "Hello"
        XCTAssertEqual(try InspectableBoxing.boxString(original).unbox(StringBinding.self), original)
        XCTAssertEqual(try InspectableBoxing.unboxString(createIReference(original)), original)
    }

    func testEnumRoundTrip() throws {
        let original = WinRTComponent_MinimalEnum.one
        XCTAssertEqual(try InspectableBoxing.boxMinimalEnum(original).unbox(WinRTComponent_MinimalEnum.self), original)
        XCTAssertEqual(try InspectableBoxing.unboxMinimalEnum(createIReference(original)), original)
    }

    func testPODStructRoundTrip() throws {
        let original = WinRTComponent_MinimalStruct(field: 42)
        XCTAssertEqual(try InspectableBoxing.boxMinimalStruct(original).unbox(WinRTComponent_MinimalStruct.self), original)
        XCTAssertEqual(try InspectableBoxing.unboxMinimalStruct(createIReference(original)), original)
    }

    func testDelegateRoundTrip() throws {
        func assertRoundTrip(roundtrip: (@escaping WinRTComponent_MinimalDelegate) throws -> WinRTComponent_MinimalDelegate) throws {
            var invoked = false
            let original: WinRTComponent_MinimalDelegate = { invoked = true }
            let roundtripped = try roundtrip(original)
            XCTAssertFalse(invoked)
            try roundtripped()
            XCTAssertTrue(invoked)
        }

        try assertRoundTrip {
            let ireference = try createIReference($0, binding: WinRTComponent_MinimalDelegateBinding.self)
            return try XCTUnwrap(ireference.value)
        }

        try assertRoundTrip {
            let iinspectable = try InspectableBoxing.boxMinimalDelegate($0)
            return try XCTUnwrap(iinspectable.unbox(WinRTComponent_MinimalDelegateBinding.self))
        }

        try assertRoundTrip {
            let ireference = try createIReference($0, binding: WinRTComponent_MinimalDelegateBinding.self)
            return try InspectableBoxing.unboxMinimalDelegate(ireference)
        }
    }
}
