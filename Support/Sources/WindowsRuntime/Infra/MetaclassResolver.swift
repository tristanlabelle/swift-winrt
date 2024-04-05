import WindowsRuntime_ABI
import WinSDK
import class Foundation.NSLock

/// Looks up and resolves the metaclass object (aka activation factory) for runtime classes from their name.
open class MetaclassResolver {
    public init() {}

    open func getActivationFactory<COMInterface>(runtimeClass: String, interfaceID: COMInterfaceID) throws -> COMReference<COMInterface> {
        let activationFactory = try getActivationFactory(runtimeClass: runtimeClass)
        return try activationFactory.interop.queryInterface(interfaceID)
    }

    open func getActivationFactory(runtimeClass: String) throws -> COMReference<SWRT_IActivationFactory> {
        try getActivationFactory(runtimeClass: runtimeClass, interfaceID: SWRT_IActivationFactory.iid)
    }
}

extension MetaclassResolver {
    public static let `default`: MetaclassResolver = Default()

    private class Default: MetaclassResolver {
        override func getActivationFactory<COMInterface>(runtimeClass: String, interfaceID: COMInterfaceID) throws -> COMReference<COMInterface> {
            var activatableId = try PrimitiveProjection.String.toABI(runtimeClass)
            defer { PrimitiveProjection.String.release(&activatableId) }

            var iid = GUIDProjection.toABI(interfaceID)
            var rawPointer: UnsafeMutableRawPointer?
            try WinRTError.throwIfFailed(WindowsRuntime_ABI.SWRT_RoGetActivationFactory(activatableId, &iid, &rawPointer))
            guard let rawPointer else { throw HResult.Error.noInterface }

            let pointer = rawPointer.bindMemory(to: COMInterface.self, capacity: 1)
            return COM.COMReference(transferringRef: pointer)
        }
    }
}

extension MetaclassResolver {
    public static func fromDll(name: String) -> MetaclassResolver { Dll(name: name) }
    public static func fromDll(moduleHandle: HMODULE) -> MetaclassResolver { Dll(moduleHandle: moduleHandle) }

    private class Dll: MetaclassResolver {
        private let libraryNameToLoad: String?
        private let lock = NSLock()
        private var libraryHandle: WinSDK.HMODULE?
        private var cachedFuncPointer: WindowsRuntime_ABI.SWRT_DllGetActivationFactory?

        init(name: String) {
            self.libraryNameToLoad = name
            self.libraryHandle = nil // Loaded on demand
        }

        init(moduleHandle: HMODULE) {
            self.libraryNameToLoad = nil
            self.libraryHandle = moduleHandle
        }

        deinit {
            if libraryNameToLoad != nil, let libraryHandle {
                WinSDK.FreeLibrary(libraryHandle)
            }
        }

        var funcPointer: WindowsRuntime_ABI.SWRT_DllGetActivationFactory {
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

        override func getActivationFactory(runtimeClass: String) throws -> COMReference<SWRT_IActivationFactory> {
            var activatableId = try PrimitiveProjection.String.toABI(runtimeClass)
            defer { PrimitiveProjection.String.release(&activatableId) }

            var factoryPointer: UnsafeMutablePointer<SWRT_IActivationFactory>?
            try WinRTError.throwIfFailed(funcPointer(activatableId, &factoryPointer))
            guard let factoryPointer else { throw HResult.Error.noInterface }

            return COM.COMReference(transferringRef: factoryPointer)
        }
    }
}