import WindowsRuntime_ABI
import WinSDK
import class Foundation.NSLock

/// Resolves the activation factory for runtime classes from their name,
/// aka the COM object that implements the default constructor and
/// can be QI'd for other factory and static interfaces.
public protocol ActivationFactoryResolver {
    mutating func resolve(runtimeClass: String) throws -> IActivationFactoryBinding.ABIReference
}

public var activationFactoryResolver: any ActivationFactoryResolver = SystemActivationFactoryResolver()

/// The activation factory resolver provided by the system, delegating to RoGetActivationFactory.
/// This resolves system classes in the "Windows." namespaces and classes listed in the application manifest.
public struct SystemActivationFactoryResolver: ActivationFactoryResolver {
    public init() {}

    public func resolve(runtimeClass: String) throws -> IActivationFactoryBinding.ABIReference {
        try Self.resolve(runtimeClass: runtimeClass, interfaceID: IActivationFactoryBinding.interfaceID)
    }

    public static func resolve<ABIStruct>(runtimeClass: String, interfaceID: COMInterfaceID,
            type: ABIStruct.Type = ABIStruct.self) throws -> COMReference<ABIStruct> {
        var activatableId = try StringBinding.toABI(runtimeClass)
        defer { StringBinding.release(&activatableId) }

        var iid = GUIDBinding.toABI(interfaceID)
        var rawPointer: UnsafeMutableRawPointer?
        try WinRTError.fromABI(WindowsRuntime_ABI.SWRT_RoGetActivationFactory(activatableId, &iid, &rawPointer))
        guard let rawPointer else { throw COMError.noInterface }

        let pointer = rawPointer.bindMemory(to: ABIStruct.self, capacity: 1)
        return COM.COMReference(transferringRef: pointer)
    }
}

/// An activation factory resolver which uses the DllGetActivationFactory exported function
// from a WinRT component dll to resolve activation factories.
public final class DllActivationFactoryResolver: ActivationFactoryResolver {
    private let libraryNameToLoad: String?
    private let lock = NSLock()
    private var libraryHandle: WinSDK.HMODULE?
    private var cachedFunction: WindowsRuntime_ABI.SWRT_DllGetActivationFactory?

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

    private var function: WindowsRuntime_ABI.SWRT_DllGetActivationFactory {
        get throws {
            if let cachedFunction { return cachedFunction }

            lock.lock()
            defer { lock.unlock() }

            if let libraryNameToLoad, libraryHandle == nil {
                libraryNameToLoad.withCString(encodedAs: UTF16.self) { name in
                    libraryHandle = WinSDK.LoadLibraryW(name)
                }
                guard libraryHandle != nil else { throw COMError.fail }
            }

            guard let rawFuncPointer = WinSDK.GetProcAddress(libraryHandle, "DllGetActivationFactory") else {
                throw COMError.fail
            }

            let funcPointer = unsafeBitCast(rawFuncPointer, to: WindowsRuntime_ABI.SWRT_DllGetActivationFactory.self)
            self.cachedFunction = funcPointer
            return funcPointer
        }
    }

    public func resolve(runtimeClass: String) throws -> IActivationFactoryBinding.ABIReference {
        var activatableId = try StringBinding.toABI(runtimeClass)
        defer { StringBinding.release(&activatableId) }

        var factoryPointer: UnsafeMutablePointer<SWRT_IActivationFactory>?
        try WinRTError.fromABI(function(activatableId, &factoryPointer))
        guard let factoryPointer else { throw COMError.noInterface }

        return COM.COMReference(transferringRef: factoryPointer)
    }
}