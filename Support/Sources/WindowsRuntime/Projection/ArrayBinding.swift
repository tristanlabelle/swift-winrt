import COM

/// Binds a WinRT array to a Swift array.
public enum ArrayBinding<ElementBinding: ABIBinding>: ABIBinding {
    // WinRT does not have a distinct representation for null and empty
    public typealias SwiftValue = [ElementBinding.SwiftValue]
    public typealias ABIValue = COMArray<ElementBinding.ABIValue>

    public static var abiDefaultValue: ABIValue { .null }

    public static func fromABI(_ value: ABIValue) -> SwiftValue {
        guard value.count > 0 else { return [] }
        return .init(unsafeUninitializedCapacity: Int(value.count)) { buffer, initializedCount in
            for i in 0..<Int(value.count) {
                buffer.initializeElement(at: i, to: ElementBinding.fromABI(value[i]))
                initializedCount = i + 1
            }
        }
    }

    public static func fromABI(pointer: UnsafeMutablePointer<ElementBinding.ABIValue>?, count: UInt32) -> SwiftValue {
        if let pointer {
            return fromABI(COMArray(pointer: pointer, count: count))
        } else {
            assert(count == 0)
            return []
        }
    }

    public static func toABI(_ value: SwiftValue) throws -> ABIValue {
        guard value.count > 0 else { return .init() }

        var result = ABIValue.allocate(count: UInt32(value.count))
        for i in 0..<Int(result.count) {
            do { result[i] = try ElementBinding.toABI(value[i]) }
            catch {
                for j in 0..<i { ElementBinding.release(&result[j]) }
                result.deallocate()
                throw error
            }
        }

        return result
    }

    public static func release(_ value: inout ABIValue) {
        guard let buffer = value.buffer else { return }
        for i in 0..<buffer.count { ElementBinding.release(&buffer[i]) }
        value.deallocate()
    }
}