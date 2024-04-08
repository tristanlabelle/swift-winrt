// Public types and protocols in here must be compatible with what the code generator would emit.

/// Represents an immutable view into a vector.
public typealias WindowsFoundationCollections_IVectorView<T> = any WindowsFoundationCollections_IVectorViewProtocol<T>

/// Represents an immutable view into a vector.
public protocol WindowsFoundationCollections_IVectorViewProtocol<T>: WindowsFoundationCollections_IIterableProtocol {
    associatedtype T

    /// Returns the item at the specified index in the vector view.
    /// - Parameter index: The zero-based index of the item.
    /// - Returns: The item at the specified index.
    func getAt(_ index: Swift.UInt32) throws -> T

    /// Retrieves the index of a specified item in the vector view.
    /// - Parameter value: The item to find in the vector view.
    /// - Parameter index: If the item is found, this is the zero-based index of the item; otherwise, this parameter is 0.
    /// - Returns: **true** if the item is found; otherwise, **false**.
    func indexOf(_ value: T, _ index: inout Swift.UInt32) throws -> Swift.Bool

    /// Gets a collection of items from the vector view beginning at the given index.
    /// - Parameter startIndex: The zero-based index to start at.
    /// - Parameter items: An array to copy the items into.
    /// - Returns: A status code indicating the result of the operation.
    func getMany(_ startIndex: Swift.UInt32, _ items: [T]) throws -> Swift.UInt32

    /// Gets the number of items in the vector view.
    /// - Returns: The number of items in the vector view.
    func _size() throws -> Swift.UInt32
}

extension WindowsFoundationCollections_IVectorViewProtocol {
    /// Gets the number of items in the vector view.
    /// - Returns: The number of items in the vector view.
    public var size: Swift.UInt32 {
        try! self._size()
    }
}