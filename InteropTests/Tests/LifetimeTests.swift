import XCTest
import WindowsRuntime
import WinRTComponent

class LifetimeTests: WinRTTestCase {
    func testActivatedObjectDestroyedWhenUnreferencedFromSwift() throws {
        var destroyed: Bool = false
        withExtendedLifetime(try DestructionCallback { destroyed = true }) {
            XCTAssertFalse(destroyed)
        }
        XCTAssertTrue(destroyed)
    }

    func testActivatedObjectDestroyedWhenUnreferencedFromWinRT() throws {
        var destroyed: Bool = false
        let objectReferencer = try ObjectReferencer(
            try DestructionCallback { destroyed = true })
        XCTAssertFalse(destroyed)
        try objectReferencer.clear()
        XCTAssertTrue(destroyed)
    }

    class ComposedDestructionCallback: DestructionCallback, @unchecked Sendable {
        private let deinitCallback: () -> Void

        public init(winRT: @escaping () -> Void, swift: @escaping () -> Void) throws {
            self.deinitCallback = swift
            try super.init(winRT)
        }

        deinit {
            deinitCallback()
        }
    }

    func testComposedObjectDestroyedWhenUnreferencedFromSwift() throws {
        var destroyed: Bool = false
        var deinited: Bool = false
        withExtendedLifetime(try ComposedDestructionCallback(
                winRT: { destroyed = true },
                swift: { deinited = true })) {
            XCTAssertFalse(destroyed)
            XCTAssertFalse(deinited)
        }
        XCTAssertTrue(destroyed)
        XCTAssertTrue(deinited)
    }

    func testComposedObjectDestroyedWhenUnreferencedFromWinRT() throws {
        var destroyed: Bool = false
        var deinited: Bool = false
        let objectReferencer = try ObjectReferencer(
            try ComposedDestructionCallback(
                winRT: { destroyed = true },
                swift: { deinited = true }))
        XCTAssertFalse(destroyed)
        XCTAssertFalse(deinited)
        try objectReferencer.clear()
        XCTAssertTrue(destroyed)
        XCTAssertTrue(deinited)
    }
}