import WindowsRuntime

extension Collection where Index == Int {
    public func toWinRTIVectorView(elementEquals: @escaping (Element, Element) -> Bool) -> WindowsFoundationCollections_IVectorView<Element> {
        CollectionVectorView(self, elementEquals: elementEquals)
    }
}

extension Collection where Index == Int, Element: Equatable {
    public func toWinRTIVectorView() -> WindowsFoundationCollections_IVectorView<Element> {
        CollectionVectorView(self, elementEquals: ==)
    }
}

fileprivate class CollectionVectorView<C: Collection>: WinRTPrimaryExport<IInspectableProjection>,
        WindowsFoundationCollections_IVectorViewProtocol
        where C.Index == Int {
    public typealias T = C.Element

    public var collection: C
    public var elementEquals: (T, T) -> Bool

    init(_ collection: C, elementEquals: @escaping (T, T) -> Bool) {
        self.collection = collection
        self.elementEquals = elementEquals
    }

    public func _size() throws -> UInt32 {
        UInt32(collection.count)
    }

    public func first() throws -> WindowsFoundationCollections_IIterator<T> {
        SequenceIterator(collection.makeIterator())
    }

    public func getAt(_ index: UInt32) throws -> C.Element {
        collection[Int(index)]
    }

    public func indexOf(_ value: C.Element, _ index: inout UInt32) throws -> Bool {
        if let foundIndex = collection.firstIndex(where: { elementEquals($0, value) }) {
            index = UInt32(foundIndex)
            return true
        } else {
            index = 0
            return false
        }
    }

    public func getMany(_ startIndex: UInt32, _ items: [C.Element]) throws -> UInt32 {
        throw HResult.Error.notImpl // TODO(#31): Implement out arrays
    }
}