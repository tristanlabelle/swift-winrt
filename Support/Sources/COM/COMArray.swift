import CWinRTCore
import WinSDK

public struct COMArray<Element> {
    public static var null: Self { .init() }

    public var elements: UnsafeMutablePointer<Element>?
    public var count: UInt32

    public init() {
        elements = nil
        count = 0
    }

    public init(elements: UnsafeMutablePointer<Element>, count: UInt32) {
        self.elements = elements
        self.count = count
    }

    public var buffer: UnsafeMutableBufferPointer<Element>? {
        guard let elements = elements else { return nil }
        return .init(start: elements, count: Int(count))
    }

    public var isNull: Bool { elements == nil }

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
            elements: allocation.bindMemory(to: Element.self, capacity: Int(count)),
            count: count)
    }

    public mutating func deallocate() {
        if let elements {
            WinSDK.CoTaskMemFree(UnsafeMutableRawPointer(elements))
            self.elements = nil
            self.count = 0
        }
    }
}
