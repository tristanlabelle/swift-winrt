import XCTest
import WinRTComponent

class BuiltInConformancesTests: WinRTTestCase {
    func testCodable() throws {
        func isCodable<T>(type: T.Type) -> Bool { T.self is any Decodable.Type && T.self is any Codable.Type }

        XCTAssertTrue(isCodable(type: MinimalEnum.self))
        XCTAssertTrue(isCodable(type: MinimalStruct.self))
        XCTAssertFalse(isCodable(type: MinimalClass.self))
        XCTAssertFalse(isCodable(type: MinimalDelegate.self))
    }

    func testHashable() throws {
        func isHashable<T>(type: T.Type) -> Bool { T.self is any Hashable.Type }

        XCTAssertTrue(isHashable(type: MinimalEnum.self))
        XCTAssertTrue(isHashable(type: MinimalStruct.self))
        XCTAssertFalse(isHashable(type: MinimalClass.self))
        XCTAssertFalse(isHashable(type: MinimalDelegate.self))
    }

    func testSendable() throws {
        let minimalEnum: MinimalEnum = .init()
        let minimalStruct: MinimalStruct = .init()
        Task {
            // Should compile if they are Sendable
            let _ = minimalEnum
            let _ = minimalStruct
        }
    }
}