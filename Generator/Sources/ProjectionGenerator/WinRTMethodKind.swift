import DotNetMetadata

enum WinRTMethodKind {
    case regular
    case constructor
    case propertyGetter
    case propertySetter
    case eventAdder
    case eventRemover
    case delegateInvoke

    // No finalizers, no static constructors, no misc property/event accessors, no indexers, no operator overloads
    public init(from method: Method) {
        if method.name.starts(with: "get_") { self = .propertyGetter }
        else if method.name.starts(with: "set_") { self = .propertySetter }
        else if method.name.starts(with: "add_") { self = .eventAdder }
        else if method.name.starts(with: "remove_") { self = .eventRemover }
        else if method.name == ".ctor" { self = .constructor }
        else if method.name == "Invoke" && method.definingType is DelegateDefinition { self = .delegateInvoke }
        else { self = .regular }
    }
}