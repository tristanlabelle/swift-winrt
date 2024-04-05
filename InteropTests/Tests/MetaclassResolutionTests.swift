import XCTest
import WindowsRuntime
import WinRTComponent

class MetaclassResolutionTests: WinRTTestCase {
    func testOverride() throws {
        // Temporarily install the new resolver (avoid affecting other tests)
        let originalResolveMetaclass = WinRTComponent.resolveMetaclass
        
        var lastRuntimeClass: String? = nil
        func customResolveMetaclass(runtimeClass: String) throws -> IInspectableReference {
            lastRuntimeClass = runtimeClass
            return try originalResolveMetaclass(runtimeClass)
        }

        WinRTComponent.resolveMetaclass = customResolveMetaclass
        defer { WinRTComponent.resolveMetaclass = originalResolveMetaclass }

        // Trigger the metaclass resolution
        try ForCustomMetaclassResolution.method()

        // Verify that the custom resolver was called
        XCTAssertEqual(lastRuntimeClass, "WinRTComponent.ForCustomMetaclassResolution")
    }
}