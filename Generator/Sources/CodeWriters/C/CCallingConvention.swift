public enum CCallingConvention {
    case cdecl
    case stdcall
}

extension CCallingConvention {
    public var keyword: String {
        switch self {
            case .cdecl: return "__cdecl"
            case .stdcall: return "__stdcall"
        }
    }
}