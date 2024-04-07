import XCTest
import WindowsRuntime
import WinRTComponent

class InterfaceImplementationTests: WinRTTestCase {
    func testWithSwiftObject() throws {
        class Exported: WinRTExport<IInspectableProjection>, IMinimalInterfaceProtocol {
            override class var implements: [Implements] { [
                .init(IMinimalInterfaceProjection.self)
            ] }

            func method() throws {}
        }

        XCTAssertNotNil(try InterfaceCasting.asMinimalInterface(Exported()))
    }

    func testWithDerivedClass() throws {
        class Derived: MinimalBaseClass, IMinimalInterfaceProtocol {
            public override init() throws { try super.init() }

            override func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
                if id == IMinimalInterfaceProjection.interfaceID {
                    // TODO
                }
                return try super._queryInterface(id)
            }

            func method() throws {}
        }

        try XCTSkipIf(true, "TODO: Implement _queryInterface delegating to a composable class identity")
        XCTAssertNotNil(try InterfaceCasting.asMinimalInterface(Derived()))
    }
}