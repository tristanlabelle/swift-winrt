public protocol SwiftWrapperFactory {
    func create<Projection: COMProjection>(
        _ reference: consuming COMReference<Projection.COMInterface>,
        projection: Projection.Type) -> Projection.SwiftObject
}

public struct DefaultSwiftWrapperFactory: SwiftWrapperFactory {
    public init() {}

    public func create<Projection: COMProjection>(
            _ reference: consuming COMReference<Projection.COMInterface>,
            projection: Projection.Type) -> Projection.SwiftObject {
        Projection._wrap(consume reference)
    }
}

public var swiftWrapperFactory: any SwiftWrapperFactory = DefaultSwiftWrapperFactory()