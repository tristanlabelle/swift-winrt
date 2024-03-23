import WindowsRuntime_ABI

public typealias IUnknownPointer = UnsafeMutablePointer<WindowsRuntime_ABI.SWRT_IUnknown>

extension IUnknownPointer {
    public func cast<COMInterface>(to type: COMInterface.Type = COMInterface.self) -> UnsafeMutablePointer<COMInterface> {
        self.withMemoryRebound(to: COMInterface.self, capacity: 1) { $0 }
    }

    // UnsafeMutableRawPointer helpers
    public static func cast(_ pointer: UnsafeMutableRawPointer) -> IUnknownPointer {
        pointer.bindMemory(to: IUnknownPointer.Pointee.self, capacity: 1)
    }

    // UnsafeMutablePointer<Interface> helpers
    public static func cast<Interface>(_ pointer: UnsafeMutablePointer<Interface>) -> IUnknownPointer {
        pointer.withMemoryRebound(to: IUnknownPointer.Pointee.self, capacity: 1) { $0 }
    }
}