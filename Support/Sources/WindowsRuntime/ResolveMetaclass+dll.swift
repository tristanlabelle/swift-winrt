import WindowsRuntime_ABI
import WinSDK
import class Foundation.NSLock

public func createResolveMetaclassFromDll(name: String) -> ResolveMetaclass {
    DllMetaclassResolver(name: name).resolve
}

public func createResolveMetaclassFromDll(moduleHandle: HMODULE) -> ResolveMetaclass {
    DllMetaclassResolver(moduleHandle: moduleHandle).resolve
}

fileprivate class DllMetaclassResolver {
    private let libraryNameToLoad: String?
    private let lock = NSLock()
    private var libraryHandle: WinSDK.HMODULE?
    private var cachedFuncPointer: WindowsRuntime_ABI.SWRT_DllGetActivationFactory?

    public init(name: String) {
        self.libraryNameToLoad = name
        self.libraryHandle = nil // Loaded on demand
    }

    public init(moduleHandle: HMODULE) {
        self.libraryNameToLoad = nil
        self.libraryHandle = moduleHandle
    }

    deinit {
        if libraryNameToLoad != nil, let libraryHandle {
            WinSDK.FreeLibrary(libraryHandle)
        }
    }

    private var funcPointer: WindowsRuntime_ABI.SWRT_DllGetActivationFactory {
        get throws {
            if let cachedFuncPointer { return cachedFuncPointer }

            lock.lock()
            defer { lock.unlock() }

            if let libraryNameToLoad, libraryHandle == nil {
                libraryNameToLoad.withCString(encodedAs: UTF16.self) { name in
                    libraryHandle = WinSDK.LoadLibraryW(name)
                }
                guard libraryHandle != nil else { throw HResult.Error.fail }
            }

            guard let rawFuncPointer = WinSDK.GetProcAddress(libraryHandle, "DllGetActivationFactory") else {
                throw HResult.Error.fail
            }

            let funcPointer = unsafeBitCast(rawFuncPointer, to: WindowsRuntime_ABI.SWRT_DllGetActivationFactory.self)
            self.cachedFuncPointer = funcPointer
            return funcPointer
        }
    }

    public func resolve(runtimeClass: String) throws -> COMReference<SWRT_IInspectable> {
        var activatableId = try WinRTPrimitiveProjection.String.toABI(runtimeClass)
        defer { WinRTPrimitiveProjection.String.release(&activatableId) }

        var factoryPointer: UnsafeMutablePointer<SWRT_IActivationFactory>?
        try WinRTError.throwIfFailed(funcPointer(activatableId, &factoryPointer))
        guard let factoryPointer else { throw HResult.Error.noInterface }

        return COM.COMReference(transferringRef: factoryPointer).reinterpret()
    }
}