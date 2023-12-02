import COM
import XCTest

internal func assertCOMIdentical(_ lhs: IUnknown, _ rhs: IUnknown, file: StaticString = #file, line: UInt = #line) {
    let lhsPointer = try! lhs._queryInterfacePointer(IUnknownProjection.self)
    defer { lhsPointer.release() }

    let rhsPointer = try! rhs._queryInterfacePointer(IUnknownProjection.self)
    defer { rhsPointer.release() }

    XCTAssertEqual(lhsPointer, rhsPointer, file: file, line: line)
}