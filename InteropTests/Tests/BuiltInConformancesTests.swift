import XCTest
import WinRTComponent

class BuiltInConformancesTests: WinRTTestCase {
    func testCodable() throws {
        func isCodable<T>(type: T.Type) -> Bool { T.self is any Decodable.Type && T.self is any Codable.Type }

        XCTAssertTrue(isCodable(type: WinRTComponent_MinimalEnum.self))
        XCTAssertTrue(isCodable(type: WinRTComponent_MinimalStruct.self))
        XCTAssertFalse(isCodable(type: WinRTComponent_MinimalClass.self))
        XCTAssertFalse(isCodable(type: WinRTComponent_MinimalDelegate.self))
    }

    func testHashable() throws {
        func isHashable<T>(type: T.Type) -> Bool { T.self is any Hashable.Type }

        XCTAssertTrue(isHashable(type: WinRTComponent_MinimalEnum.self))
        XCTAssertTrue(isHashable(type: WinRTComponent_MinimalStruct.self))
        XCTAssertFalse(isHashable(type: WinRTComponent_MinimalClass.self))
        XCTAssertFalse(isHashable(type: WinRTComponent_MinimalDelegate.self))
    }

    func testSendable() throws {
        let minimalEnum: WinRTComponent_MinimalEnum = .init()
        let minimalStruct: WinRTComponent_MinimalStruct = .init()
        Task {
            // Should compile if they are Sendable
            let _ = minimalEnum
            let _ = minimalStruct
        }
    }
}