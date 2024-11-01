import XCTest
import WindowsRuntime
import WinRTComponent

class EventTests: WinRTTestCase {
    func testImportedEvent() throws {
        let eventSource = try XCTUnwrap(Events.createSource())

        var count = 0
        var registration = try eventSource.event { count += 1 }

        XCTAssertEqual(count, 0)
        try eventSource.fire()
        XCTAssertEqual(count, 1)

        try registration.remove()
        try eventSource.fire()
        XCTAssertEqual(count, 1)
    }

    func testExportedEvent() throws {
        let eventSource = EventSource()
        let counter = try XCTUnwrap(Events.createCounter(eventSource))
        XCTAssertEqual(try counter.count, 0)
        try eventSource.fire()
        XCTAssertEqual(try counter.count, 1)
        try counter.detach()
        try eventSource.fire()
        XCTAssertEqual(try counter.count, 1)

        class EventSource: WinRTPrimaryExport<IEventSourceBinding>, IEventSourceProtocol {
            private var invocationList: EventInvocationList<MinimalDelegate> = .init()

            func event(adding handler: MinimalDelegate?) throws -> EventRegistration {
                try invocationList.add(handler)
            }

            func event(removing token: WindowsRuntime.EventRegistrationToken) throws {
                try invocationList.remove(token)
            }

            func fire() throws {
                try invocationList.invoke { try $0() }
            }
        }
    }
}