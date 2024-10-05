import COM
import XCTest

internal func assertCOMIdentical(_ lhs: IUnknown, _ rhs: IUnknown, file: StaticString = #file, line: UInt = #line) {
    do {
        let lhsReference = try lhs._queryInterface(IUnknownBinding.self)
        let rhsReference = try rhs._queryInterface(IUnknownBinding.self)
        XCTAssertEqual(lhsReference.pointer, rhsReference.pointer, file: file, line: line)
    }
    catch {
        XCTFail("Failed to query IUnknown from objects: \(error)", file: file, line: line)
    }
}