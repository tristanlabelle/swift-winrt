public protocol SwiftWrapperFactory {
    func create<Binding: COMBinding>(
        _ reference: consuming Binding.ABIReference,
        binding: Binding.Type) -> Binding.SwiftObject
}

public struct DefaultSwiftWrapperFactory: SwiftWrapperFactory {
    public init() {}

    public func create<Binding: COMBinding>(
            _ reference: consuming Binding.ABIReference,
            binding: Binding.Type) -> Binding.SwiftObject {
        Binding._wrap(consume reference)
    }
}

public var swiftWrapperFactory: any SwiftWrapperFactory = DefaultSwiftWrapperFactory()