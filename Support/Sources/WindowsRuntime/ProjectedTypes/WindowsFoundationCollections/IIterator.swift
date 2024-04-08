// Public types and protocols in here must be compatible with what the code generator would emit.

/// Supports simple iteration over a collection.
public typealias WindowsFoundationCollections_IIterator<T> = any WindowsFoundationCollections_IIteratorProtocol<T>

/// Supports simple iteration over a collection.
public protocol WindowsFoundationCollections_IIteratorProtocol<T>: IInspectableProtocol {
    associatedtype T

    /// Advances the iterator to the next item in the collection.
    /// - Returns: True if the iterator refers to a valid item in the collection; false if the iterator passes the end of the collection.
    func moveNext() throws -> Swift.Bool

    /// Retrieves all items in the collection.
    /// - Parameter items: The items in the collection.
    /// - Returns: The number of items in the collection.
    func getMany(_ items: [T]) throws -> Swift.UInt32

    /// Gets the current item in the collection.
    /// - Returns: The current item in the collection.
    func _current() throws -> T

    /// Gets a value that indicates whether the iterator refers to a current item or is at the end of the collection.
    /// - Returns: True if the iterator refers to a valid item in the collection; otherwise, false.
    func _hasCurrent() throws -> Swift.Bool
}

extension WindowsFoundationCollections_IIteratorProtocol {
    /// Gets the current item in the collection.
    /// - Returns: The current item in the collection.
    public var current: T {
        try! self._current()
    }

    /// Gets a value that indicates whether the iterator refers to a current item or is at the end of the collection.
    /// - Returns: True if the iterator refers to a valid item in the collection; otherwise, false.
    public var hasCurrent: Swift.Bool {
        try! self._hasCurrent()
    }
}