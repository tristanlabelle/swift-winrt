/// Exposes an iterator that supports simple iteration over a collection of a specified type.
public typealias WindowsFoundationCollections_IIterable<T> = any WindowsFoundationCollections_IIterableProtocol<T>

/// Exposes an iterator that supports simple iteration over a collection of a specified type.
public protocol WindowsFoundationCollections_IIterableProtocol<T>: IInspectableProtocol {
    associatedtype T

    /// Returns an iterator for the items in the collection.
    /// - Returns: The iterator.
    func first() throws -> WindowsFoundationCollections_IIterator<T>
}

extension WindowsFoundationCollections_IIterableProtocol {
    /// Gets a Swift iterator for this WinRt IIterable.
    public func makeIterator() throws -> WinRTIterator<T> {
        WinRTIterator(try first())
    }
}

/// Implements the Swift IteratorProtocol for a WinRT IIterable.
public struct WinRTIterator<Element>: Swift.IteratorProtocol {
    private let iterator: WindowsFoundationCollections_IIterator<Element>
    private var first: Bool = true

    internal init(_ iterator: WindowsFoundationCollections_IIterator<Element>) {
        self.iterator = iterator
    }

    public mutating func next() -> Element? {
        if first {
            first = false
            guard (try? iterator._hasCurrent()) ?? false else { return nil }
        } else {
            guard (try? iterator.moveNext()) ?? false else { return nil }
        }
        return try? iterator._current()
    }
}