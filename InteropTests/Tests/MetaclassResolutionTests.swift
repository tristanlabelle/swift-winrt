import XCTest
import WindowsRuntime
import WinRTComponent

class MetaclassResolutionTests: WinRTTestCase {
    func testCustomResolver() throws {
        class Resolver: WinRTMetaclassResolver {
            private let dllResolver = WinRTMetaclassResolver.fromDll(name: "WinRTComponent")
            var lastRuntimeClass: String? = nil

            override func getActivationFactory(runtimeClass: String) throws -> COMReference<IActivationFactoryProjection.COMInterface> {
                lastRuntimeClass = runtimeClass
                return try dllResolver.getActivationFactory(runtimeClass: runtimeClass)
            }
        }

        // Temporarily install the new resolver (avoid affecting other tests)
        let resolver = Resolver()
        let originalResolver = WinRTComponent.metaclassResolver
        WinRTComponent.metaclassResolver = resolver
        defer { WinRTComponent.metaclassResolver = originalResolver }

        // Trigger the metaclass resolution
        try ForCustomMetaclassResolution.method()

        // Verify that the custom resolver was called
        XCTAssertEqual(resolver.lastRuntimeClass, "WinRTComponent.ForCustomMetaclassResolution")
    }
}