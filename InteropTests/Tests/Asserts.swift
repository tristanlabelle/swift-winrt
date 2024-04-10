import COM
import XCTest

internal func assertCOMIdentical(_ lhs: AnyObject, _ rhs: AnyObject, file: StaticString = #file, line: UInt = #line) {
    guard let lhsUnknown = lhs as? IUnknown, let rhsUnknown = rhs as? IUnknown else {
        XCTFail("One or both objects are not COM objects", file: file, line: line)
        return
    }

    do {
        let lhsReference = try lhsUnknown._queryInterface(IUnknownProjection.self)
        let rhsReference = try rhsUnknown._queryInterface(IUnknownProjection.self)
        XCTAssertEqual(lhsReference.pointer, rhsReference.pointer, file: file, line: line)
    }
    catch {
        XCTFail("Failed to query IUnknown from objects: \(error)", file: file, line: line)
    }
}