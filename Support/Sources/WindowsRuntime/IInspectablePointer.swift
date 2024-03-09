import COM
import WindowsRuntime_ABI

public typealias IInspectablePointer = UnsafeMutablePointer<SWRT_IInspectable>

extension IInspectablePointer {
    public static func cast<Interface>(_ pointer: UnsafeMutablePointer<Interface>) -> Self {
        pointer.withMemoryRebound(to: Pointee.self, capacity: 1) { $0 }
    }
}

public typealias IInspectableReference = COMReference<SWRT_IInspectable>