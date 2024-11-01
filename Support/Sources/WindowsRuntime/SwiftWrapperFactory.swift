public protocol SwiftWrapperFactory {
    func create<StaticBinding: COMBinding>(
        _ reference: consuming StaticBinding.ABIReference,
        staticBinding: StaticBinding.Type) -> StaticBinding.SwiftObject
}

public struct DefaultSwiftWrapperFactory: SwiftWrapperFactory {
    public init() {}

    public func create<StaticBinding: COMBinding>(
            _ reference: consuming StaticBinding.ABIReference,
            staticBinding: StaticBinding.Type) -> StaticBinding.SwiftObject {
        StaticBinding._wrap(consume reference)
    }
}

public var swiftWrapperFactory: any SwiftWrapperFactory = DefaultSwiftWrapperFactory()