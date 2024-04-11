extension Array {
    public func toWinRTIVector(elementEquals: @escaping (Element, Element) -> Bool) -> ArrayVector<Element> {
        ArrayVector(self, elementEquals: elementEquals)
    }
}

extension Array where Element: Equatable {
    public func toWinRTIVector() -> ArrayVector<Element> {
        ArrayVector(self, elementEquals: ==)
    }
}

/// Wraps a Swift array into a type implementing WinRT's Windows.Foundation.Collections.IVector<T>.
public class ArrayVector<T>: WinRTPrimaryExport<IInspectableProjection>,
        WindowsFoundationCollections_IVectorProtocol, WindowsFoundationCollections_IVectorViewProtocol {
    public var array: [T]
    public var elementEquals: (T, T) -> Bool

    init(_ array: [T], elementEquals: @escaping (T, T) -> Bool) {
        self.array = array
        self.elementEquals = elementEquals
    }

    public func _size() throws -> UInt32 {
        UInt32(array.count)
    }

    public func first() throws -> WindowsFoundationCollections_IIterator<T> {
        SequenceIterator(array.makeIterator())
    }

    public func getAt(_ index: UInt32) throws -> T {
        array[Int(index)]
    }

    public func getView() throws -> WindowsFoundationCollections_IVectorView<T> {
        array.toWinRTIVectorView(elementEquals: elementEquals)
    }

    public func indexOf(_ value: T, _ index: inout UInt32) throws -> Bool {
        if let foundIndex = array.firstIndex(where: { elementEquals($0, value) }) {
            index = UInt32(foundIndex)
            return true
        } else {
            index = 0
            return false
        }
    }

    public func setAt(_ index: UInt32, _ value: T) throws {
        array[Int(index)] = value
    }

    public func insertAt(_ index: UInt32, _ value: T) throws {
        array.insert(value, at: Int(index))
    }

    public func removeAt(_ index: UInt32) throws {
        array.remove(at: Int(index))
    }

    public func append(_ value: T) throws {
        array.append(value)
    }

    public func removeAtEnd() throws {
        array.removeLast()
    }

    public func clear() throws {
        array.removeAll()
    }

    public func getMany(_ startIndex: UInt32, _ items: [T]) throws -> UInt32 {
        throw HResult.Error.notImpl // TODO(#31): Implement out arrays
    }

    public func replaceAll(_ items: [T]) throws {
        array = items
    }
}
