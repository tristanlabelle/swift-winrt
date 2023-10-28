import COM

public enum WinRTArrayProjection<ElementProjection: ABIProjection>: ABIProjection {
    // WinRT does not have a distinct representation for null and empty
    public typealias SwiftValue = [ElementProjection.SwiftValue]
    public typealias ABIValue = COMArray<ElementProjection.ABIValue>

    public static var abiDefaultValue: ABIValue { .null }

    public static func toSwift(copying value: ABIValue) -> SwiftValue {
        guard value.count > 0 else { return [] }
        return .init(unsafeUninitializedCapacity: Int(value.count)) {
            for i in 0..<Int(value.count) {
                $0.initializeElement(at: i, to: ElementProjection.toSwift(copying: value[i]))
                $1 = i
            }
        }
    }

    public static func toSwift(consuming value: inout ABIValue) -> SwiftValue {
        guard value.count > 0 else { return [] }
        let result = SwiftValue(unsafeUninitializedCapacity: Int(value.count)) {
            for i in 0..<Int(value.count) {
                $0.initializeElement(at: i, to: ElementProjection.toSwift(consuming: &value[i]))
                $1 = i
            }
        }
        value.deallocate()
        return result
    }

    public static func toABI(_ value: SwiftValue) throws -> ABIValue {
        guard value.count > 0 else { return .init() }

        var result = ABIValue.allocate(count: UInt32(value.count))
        for i in 0..<Int(result.count) {
            do { result[i] = try ElementProjection.toABI(value[i]) }
            catch {
                for j in 0..<i { ElementProjection.release(&result[j]) }
                result.deallocate()
                throw error
            }
        }

        return result
    }

    public static func release(_ value: inout ABIValue) {
        guard let buffer = value.buffer else { return }
        for i in 0..<buffer.count { ElementProjection.release(&buffer[i]) }
        value.deallocate()
    }
}