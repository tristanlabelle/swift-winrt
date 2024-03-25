import WindowsRuntime_ABI
import WinSDK
import class Foundation.NSLock

/// Supports class instantiation for the WinRT projection.
open class WinRTClassLoader {
    open func getActivationFactory<COMInterface>(runtimeClass: String, interfaceID: COMInterfaceID) throws -> COMReference<COMInterface> {
        try getActivationFactory(runtimeClass: runtimeClass).reinterpret(to: COMInterface.self)
    }

    open func getActivationFactory(runtimeClass: String) throws -> COMReference<SWRT_IActivationFactory> {
        try getActivationFactory(runtimeClass: runtimeClass, interfaceID: SWRT_IActivationFactory.iid)
    }
}

extension WinRTClassLoader {
    public static let `default`: WinRTClassLoader = Default()

    private class Default: WinRTClassLoader {
        override func getActivationFactory<COMInterface>(runtimeClass: String, interfaceID: COMInterfaceID) throws -> COMReference<COMInterface> {
            var activatableId = try WinRTPrimitiveProjection.String.toABI(runtimeClass)
            defer { WinRTPrimitiveProjection.String.release(&activatableId) }

            var iid = GUIDProjection.toABI(interfaceID)
            var rawPointer: UnsafeMutableRawPointer?
            try WinRTError.throwIfFailed(WindowsRuntime_ABI.SWRT_RoGetActivationFactory(activatableId, &iid, &rawPointer))
            guard let rawPointer else { throw HResult.Error.noInterface }

            let pointer = rawPointer.bindMemory(to: COMInterface.self, capacity: 1)
            return COM.COMReference(transferringRef: pointer)
        }
    }
}

extension WinRTClassLoader {
    public static func dll(name: String) -> WinRTClassLoader { Dll(name: name) }

    private class Dll: WinRTClassLoader {
        private let name: String
        private let lock = NSLock()
        private var libraryHandle: WinSDK.HMODULE?
        private var cachedFuncPointer: WindowsRuntime_ABI.SWRT_DllGetActivationFactory?

        init(name: String) {
            self.name = name
        }

        deinit {
            if let libraryHandle {
                WinSDK.FreeLibrary(libraryHandle)
            }
        }

        var funcPointer: WindowsRuntime_ABI.SWRT_DllGetActivationFactory {
            get throws {
                if let cachedFuncPointer { return cachedFuncPointer }

                lock.lock()
                defer { lock.unlock() }

                if libraryHandle == nil {
                    name.withCString(encodedAs: UTF16.self) { name in
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
            var activatableId = try WinRTPrimitiveProjection.String.toABI(runtimeClass)
            defer { WinRTPrimitiveProjection.String.release(&activatableId) }

            var factoryPointer: UnsafeMutablePointer<SWRT_IActivationFactory>?
            try WinRTError.throwIfFailed(funcPointer(activatableId, &factoryPointer))
            guard let factoryPointer else { throw HResult.Error.noInterface }

            return COM.COMReference(transferringRef: factoryPointer)
        }
    }
}