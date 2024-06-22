import WindowsRuntime

extension Sequence {
    /// Converts a Swift sequence to a WinRT IIterable.
    /// - Parameter sequence: The sequence to convert.
    /// - Returns: The converted IIterable.
    public func toWinRTIIterable() -> WindowsFoundationCollections_IIterable<Element> {
        SequenceIterable(self)
    }
}

fileprivate class SequenceIterable<S: Sequence>: WinRTPrimaryExport<IInspectableProjection>, WindowsFoundationCollections_IIterableProtocol {
    typealias T = S.Element

    private let sequence: S

    init(_ sequence: S) {
        self.sequence = sequence
    }

    func first() throws -> WindowsFoundationCollections_IIterator<S.Element> {
        SequenceIterator(sequence.makeIterator())
    }
}

internal class SequenceIterator<I: IteratorProtocol>: WinRTPrimaryExport<IInspectableProjection>, WindowsFoundationCollections_IIteratorProtocol {
    typealias T = I.Element

    private var iterator: I
    private var current: T?

    init(_ iterator: I) {
        self.iterator = iterator
        self.current = self.iterator.next()
    }

    func _hasCurrent() throws -> Bool { current != nil }

    func _current() throws -> T {
        guard let current else { throw HResult.Error.illegalMethodCall }
        return current
    }

    func moveNext() throws -> Bool {
        current = iterator.next()
        return current != nil
    }

    func getMany(_ items: [I.Element]) throws -> UInt32 {
        throw HResult.Error.notImpl // TODO(#31): Implement out arrays
    }
}