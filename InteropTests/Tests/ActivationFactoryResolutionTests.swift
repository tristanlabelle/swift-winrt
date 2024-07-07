import XCTest
import WindowsRuntime
import WinRTComponent

class ActivationFactoryResolutionTests: WinRTTestCase {
    func testCustomResolver() throws {
        class Resolver: ActivationFactoryResolver {
            private let dllResolver = DllActivationFactoryResolver(name: "WinRTComponent.dll")
            var lastRuntimeClass: String? = nil

            func resolve(runtimeClass: String) throws -> COMReference<IActivationFactoryProjection.ABIStruct> {
                lastRuntimeClass = runtimeClass
                return try dllResolver.resolve(runtimeClass: runtimeClass)
            }
        }

        // Temporarily install the new resolver (avoid affecting other tests)
        let resolver = Resolver()
        let originalResolver = WindowsRuntime.activationFactoryResolver
        WindowsRuntime.activationFactoryResolver = resolver
        defer { WindowsRuntime.activationFactoryResolver = originalResolver }

        // Trigger the activation factory resolution
        try ForCustomActivationFactoryResolution.method()

        // Verify that the custom resolver was called
        XCTAssertEqual(resolver.lastRuntimeClass, "WinRTComponent.ForCustomActivationFactoryResolution")
    }
}