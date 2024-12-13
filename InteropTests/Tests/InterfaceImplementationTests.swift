import XCTest
import WindowsRuntime
import WinRTComponent

class InterfaceImplementationTests: WinRTTestCase {
    func testWithSwiftObject() throws {
        class Exported: WinRTExport<IInspectableBinding>, IMinimalInterfaceProtocol {
            override class var queriableInterfaces: [any COMTwoWayBinding.Type] { [
                IMinimalInterfaceBinding.self
            ] }

            var callCount: Int = 0
            func method() throws { callCount += 1 }
        }

        do {
            let exported = Exported()
            let minimalInterface = try exported.queryInterface(MinimalInterfaceBinding.self)
            XCTAssertEqual(exported.callCount, 0)
            minimalInterface.method()
            XCTAssertTrue(exported.callCount, 1)
        }

        do {
            let exported = Exported()
            let minimalInterface = try InterfaceCasting.asMinimalInterface(exported)
            XCTAssertEqual(exported.callCount, 0)
            minimalInterface.method()
            XCTAssertTrue(exported.callCount, 1)
        }
    }

    func testWithDerivedClass() throws {
        class Derived: MinimalBaseClass, IMinimalInterfaceProtocol, @unchecked Sendable {
            override class var queriableInterfaces: [any COMTwoWayBinding.Type] { [
                IMinimalInterfaceBinding.self
            ] }

            var callCount: Int = 0
            func method() throws { callCount += 1 }
        }

        do {
            let derived = Derived()
            let minimalInterface = try derived.queryInterface(MinimalInterfaceBinding.self)
            XCTAssertEqual(derived.callCount, 0)
            minimalInterface.method()
            XCTAssertTrue(derived.callCount, 1)
        }

        do {
            let derived = Derived()
            let minimalInterface = try InterfaceCasting.asMinimalInterface(derived)
            XCTAssertEqual(derived.callCount, 0)
            minimalInterface.method()
            XCTAssertTrue(derived.callCount, 1)
        }
    }
}