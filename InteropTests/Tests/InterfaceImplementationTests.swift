import XCTest
import WindowsRuntime
import WinRTComponent

class InterfaceImplementationTests: WinRTTestCase {
    func testWithSwiftObject() throws {
        class Exported: WinRTExportBase<IInspectableBinding>, IMinimalInterfaceProtocol {
            override class var queriableInterfaces: [any COMTwoWayBinding.Type] { [
                IMinimalInterfaceBinding.self
            ] }

            var callCount: Int = 0
            func method() throws { callCount += 1 }
        }

        do {
            let exported = Exported()
            let minimalInterface = try exported.queryInterface(IMinimalInterfaceBinding.self)
            XCTAssertEqual(exported.callCount, 0)
            try minimalInterface.method()
            XCTAssertEqual(exported.callCount, 1)
        }

        do {
            let exported = Exported()
            let minimalInterface = try InterfaceCasting.asMinimalInterface(exported)
            XCTAssertEqual(exported.callCount, 0)
            try minimalInterface.method()
            XCTAssertEqual(exported.callCount, 1)
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
            let derived = try Derived()
            let minimalInterface = try derived.queryInterface(IMinimalInterfaceBinding.self)
            XCTAssertEqual(derived.callCount, 0)
            try minimalInterface.method()
            XCTAssertEqual(derived.callCount, 1)
        }

        do {
            let derived = try Derived()
            let minimalInterface = try InterfaceCasting.asMinimalInterface(derived)
            XCTAssertEqual(derived.callCount, 0)
            try minimalInterface.method()
            XCTAssertEqual(derived.callCount, 1)
        }
    }
}