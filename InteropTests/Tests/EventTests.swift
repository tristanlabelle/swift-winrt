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

        class EventSource: WinRTExport<IEventSourceProjection>, IEventSourceProtocol {
            private var handlers = [(MinimalDelegate, token: EventRegistrationToken)]()
            private var nextTokenValue: Int64 = 1

            func event(adding handler: MinimalDelegate?) throws -> EventRegistration {
                guard let handler else { throw HResult.Error.pointer }
                let token = EventRegistrationToken(nextTokenValue)
                handlers.append((handler, token: token))
                nextTokenValue += 1
                return EventRegistration(token: token, remover: self.event)
            }

            func event(removing token: WindowsRuntime.EventRegistrationToken) throws {
                guard let index = handlers.firstIndex(where: { $0.token == token }) else { throw HResult.Error.invalidArg }
                handlers.remove(at: index)
            }

            func fire() throws {
                for (handler, _) in handlers { try handler() }
            }
        }
    }
}