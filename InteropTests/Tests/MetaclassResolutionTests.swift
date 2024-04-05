import XCTest
import WindowsRuntime
import WinRTComponent

class MetaclassResolutionTests: WinRTTestCase {
    func testCustomResolver() throws {
        class Resolver: MetaclassResolver {
            private let dllResolver = DllMetaclassResolver(name: "WinRTComponent.dll")
            var lastRuntimeClass: String? = nil

            func resolve(runtimeClass: String) throws -> IInspectableReference {
                lastRuntimeClass = runtimeClass
                return try dllResolver.resolve(runtimeClass: runtimeClass)
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