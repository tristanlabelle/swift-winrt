import WindowsRuntime_ABI
import WinSDK

/// A pointer-length pair representing a COM array,
/// where the buffer is allocated using the COM allocator.
/// Since this is a struct, memory managment must be done manually.
public struct COMArray<Element> {
    public static var null: Self { .init() }

    public var pointer: UnsafeMutablePointer<Element>?
    public var count: UInt32

    public init() {
        pointer = nil
        count = 0
    }

    public init(pointer: UnsafeMutablePointer<Element>, count: UInt32) {
        self.pointer = pointer
        self.count = count
    }

    public var buffer: UnsafeMutableBufferPointer<Element>? {
        guard let pointer = pointer else { return nil }
        return .init(start: pointer, count: Int(count))
    }

    public var isNull: Bool { pointer == nil }

    public subscript(index: Int) -> Element {
        get {
            precondition(index >= 0 && index < Int(count))
            return buffer![index]
        }
        set {
            precondition(index >= 0 && index < Int(count))
            buffer![index] = newValue
        }
    }

    public static func allocate(count: UInt32) -> Self {
        guard count > 0 else { return .init() }
        let allocation = WinSDK.CoTaskMemAlloc(WinSDK.SIZE_T(count)
            * WinSDK.SIZE_T(MemoryLayout<Element>.size))!
        return .init(
            pointer: allocation.bindMemory(to: Element.self, capacity: Int(count)),
            count: count)
    }

    public mutating func deallocate() {
        if let pointer {
            WinSDK.CoTaskMemFree(UnsafeMutableRawPointer(pointer))
            self.pointer = nil
            self.count = 0
        }
    }

    public mutating func detach() -> (pointer: UnsafeMutablePointer<Element>?, count: UInt32) {
        let result = (pointer, count)
        pointer = nil
        count = 0
        return result
    }
}
