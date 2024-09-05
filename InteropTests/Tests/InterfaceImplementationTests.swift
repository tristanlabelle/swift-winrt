import XCTest
import WindowsRuntime
import WinRTComponent

class InterfaceImplementationTests: WinRTTestCase {
    func testWithSwiftObject() throws {
        class Exported: WinRTPrimaryExport<IInspectableProjection>, IMinimalInterfaceProtocol {
            override class var implements: [COMImplements] { [
                .init(IMinimalInterfaceProjection.self)
            ] }

            func method() throws {}
        }

        XCTAssertNotNil(try InterfaceCasting.asMinimalInterface(Exported()))
    }

    func testWithDerivedClass() throws {
        class Derived: MinimalBaseClass, IMinimalInterfaceProtocol, @unchecked Sendable {
            override class var implements: [COMImplements] { [
                .init(IMinimalInterfaceProjection.self)
            ] }

            func method() throws {}
        }

        XCTAssertNotNil(try InterfaceCasting.asMinimalInterface(Derived()))
    }
}