import WindowsRuntime_ABI
import WinSDK
import class Foundation.NSLock

/// Resolves the metaclass object (aka activation factory) for runtime classes from their name.
///
/// WinRT doesn't have a formal metaclass concept, but the usage and API shape for activation factories
/// matches the metaclass concept: an object that exposes the class's static methods.
/// Activation factory is a misnomer because some classes are composable or static.
public protocol MetaclassResolver {
    mutating func resolve(runtimeClass: String) throws -> IInspectableReference
}

extension MetaclassResolver {
    public mutating func resolve<Interface>(runtimeClass: String, interfaceID: COMInterfaceID,
            type: Interface.Type = Interface.self) throws -> COMReference<Interface> {
        try resolve(runtimeClass: runtimeClass).queryInterface(interfaceID)
    }
}

public var metaclassResolver: any MetaclassResolver = SystemMetaclassResolver()

/// The metaclass resolver provided by the system, delegating to RoGetActivationFactory.
/// This resolves system classes in the "Windows." namespaces and classes listed in the application manifest.
public struct SystemMetaclassResolver: MetaclassResolver {
    public init() {}

    public func resolve(runtimeClass: String) throws -> IInspectableReference {
        try Self.getActivationFactory(runtimeClass: runtimeClass, interfaceID: IInspectableProjection.interfaceID)
    }

    public static func getActivationFactory<Interface>(runtimeClass: String, interfaceID: COMInterfaceID,
            type: Interface.Type = Interface.self) throws -> COMReference<Interface> {
        var activatableId = try PrimitiveProjection.String.toABI(runtimeClass)
        defer { PrimitiveProjection.String.release(&activatableId) }

        var iid = GUIDProjection.toABI(interfaceID)
        var rawPointer: UnsafeMutableRawPointer?
        try WinRTError.throwIfFailed(WindowsRuntime_ABI.SWRT_RoGetActivationFactory(activatableId, &iid, &rawPointer))
        guard let rawPointer else { throw HResult.Error.noInterface }

        let pointer = rawPointer.bindMemory(to: Interface.self, capacity: 1)
        return COM.COMReference(transferringRef: pointer)
    }
}

/// A metaclass resolver which uses exported functions from a WinRT component dll to resolve metaclasses.
public final class DllMetaclassResolver: MetaclassResolver {
    private let libraryNameToLoad: String?
    private let lock = NSLock()
    private var libraryHandle: WinSDK.HMODULE?
    private var cachedGetActivationFactoryFunc: WindowsRuntime_ABI.SWRT_DllGetActivationFactory?

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

    private var getActivationFactoryFunc: WindowsRuntime_ABI.SWRT_DllGetActivationFactory {
        get throws {
            if let cachedGetActivationFactoryFunc { return cachedGetActivationFactoryFunc }

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
            self.cachedGetActivationFactoryFunc = funcPointer
            return funcPointer
        }
    }

    public func getActivationFactory(runtimeClass: String) throws -> COMReference<IActivationFactoryProjection.COMInterface> {
        var activatableId = try PrimitiveProjection.String.toABI(runtimeClass)
        defer { PrimitiveProjection.String.release(&activatableId) }

        var factoryPointer: UnsafeMutablePointer<SWRT_IActivationFactory>?
        try WinRTError.throwIfFailed(getActivationFactoryFunc(activatableId, &factoryPointer))
        guard let factoryPointer else { throw HResult.Error.noInterface }

        return COM.COMReference(transferringRef: factoryPointer)
    }

    public func resolve(runtimeClass: String) throws -> IInspectableReference {
        try getActivationFactory(runtimeClass: runtimeClass).cast() // IActivationFactory isa IInspectable
    }
}