import COM_ABI
import COM_PrivateABI

extension COMEmbedding {
    fileprivate static func getEmbedderAndFlagsUnsafe<ABIStruct>(_ this: UnsafeMutablePointer<ABIStruct>) -> UInt {
        this.withMemoryRebound(to: SWRT_COMEmbedding.self, capacity: 1) {
            $0.pointee.swiftEmbedderAndFlags
        }
    }

    fileprivate static func getUnmanagedRefCounteeUnsafe<ABIStruct>(_ this: UnsafeMutablePointer<ABIStruct>) -> Unmanaged<AnyObject> {
        let embedderAndFlags = getEmbedderAndFlagsUnsafe(this)
        let opaquePointer = UnsafeMutableRawPointer(bitPattern: embedderAndFlags & ~SWRT_COMEmbeddingFlags_Mask)
        assert(opaquePointer != nil, "Bad COM object embedding. The embedder pointer is nil.")

        if (embedderAndFlags & SWRT_COMEmbeddingFlags_Extended) != 0 {
            // COMEmbedding asserted that we can reinterpret cast to COMEmbedderEx.
            let embedder = Unmanaged<COMEmbedderEx>.fromOpaque(opaquePointer!).takeUnretainedValue()
            return Unmanaged.passUnretained(embedder.refCountee)
        } else {
            return Unmanaged<AnyObject>.fromOpaque(opaquePointer!)
        }
    }

    fileprivate static func getIUnknownUnsafe<ABIStruct>(_ this: UnsafeMutablePointer<ABIStruct>) -> IUnknown {
        let embedderAndFlags = getEmbedderAndFlagsUnsafe(this)

        // COMEmbedding/COMImplements should guarantee that the embedder is not null,
        // and that it either implements IUnknown, or derives from COMEmbedderEx to provide an implementation.
        let opaquePointer = UnsafeMutableRawPointer(bitPattern: embedderAndFlags & ~SWRT_COMEmbeddingFlags_Mask)
        assert(opaquePointer != nil, "Bad COM object embedding. The embedder pointer is nil.")

        if (embedderAndFlags & SWRT_COMEmbeddingFlags_Extended) != 0 {
            // COMEmbedding asserted that we can reinterpret cast to COMEmbedderEx.
            return Unmanaged<COMEmbedderEx>.fromOpaque(opaquePointer!).takeUnretainedValue().unknown
        }

        let unknown =  Unmanaged<AnyObject>.fromOpaque(opaquePointer!).takeUnretainedValue() as? IUnknown
        assert(unknown != nil, "Bad COM object embedding. Did not implement IUnknown.")
        return unknown!
    }

    /// Gets the Swift object that provides the implementation for the given COM interface,
    /// assuming that it is an embedded COM interface, and otherwise crashes.
    public static func getImplementerUnsafe<ABIStruct, Implementer>(
            _ this: UnsafeMutablePointer<ABIStruct>, type: Implementer.Type = Implementer.self) -> Implementer {
        let embedderAndFlags = getEmbedderAndFlagsUnsafe(this)

        // COMEmbedding/COMImplements should guarantee that the embedder is not null,
        // and that it either implements IUnknown, or derives from COMEmbedderEx to provide an implementation.
        let opaquePointer = UnsafeMutableRawPointer(bitPattern: embedderAndFlags & ~SWRT_COMEmbeddingFlags_Mask)
        assert(opaquePointer != nil, "Bad COM object embedding. The embedder pointer is nil.")

        let implementerObject: AnyObject?
        if (embedderAndFlags & SWRT_COMEmbeddingFlags_Extended) != 0 {
            // COMEmbedding asserted that we can reinterpret cast to COMEmbedderEx.
            implementerObject = Unmanaged<COMEmbedderEx>.fromOpaque(opaquePointer!).takeUnretainedValue().implementer
        } else {
            implementerObject = Unmanaged<AnyObject>.fromOpaque(opaquePointer!).takeUnretainedValue()
        }

        let implementer = implementerObject as? Implementer
        assert(implementer != nil, "Bad COM object embedding. Did not provide the expected implementation of \(Implementer.self).")
        return implementer!
    }

    public static func getImplementer<ABIStruct, Implementer>(
            _ this: UnsafeMutablePointer<ABIStruct>, type: Implementer.Type = Implementer.self) -> Implementer? {
        do {
            _ = try COMInterop(this).queryInterface(uuidof(SWRT_COMEmbedding.self))
        } catch {
            return nil
        }

        return getImplementerUnsafe(this, type: type)
    }
}


internal func uuidof(_: SWRT_COMEmbedding.Type) -> COMInterfaceID {
    .init(0x33934271, 0x7009, 0x4EF3, 0x90F1, 0x02090D7EBD64)
}

public enum IUnknownVirtualTable {
    public static func AddRef<ABIStruct>(_ this: UnsafeMutablePointer<ABIStruct>?) -> UInt32 {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return 0
        }

        let unmanaged = COMEmbedding.getUnmanagedRefCounteeUnsafe(this)
        _ = unmanaged.retain()
        // Best effort refcount
        return UInt32(_getRetainCount(unmanaged.takeUnretainedValue()))
    }

    public static func Release<ABIStruct>(_ this: UnsafeMutablePointer<ABIStruct>?) -> UInt32 {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return 0
        }

        let unmanaged = COMEmbedding.getUnmanagedRefCounteeUnsafe(this)
        let oldRetainCount = _getRetainCount(unmanaged.takeUnretainedValue())
        unmanaged.release()
        // Best effort refcount
        return UInt32(oldRetainCount - 1)
    }

    public static func QueryInterface<ABIStruct>(
            _ this: UnsafeMutablePointer<ABIStruct>?,
            _ iid: UnsafePointer<SWRT_Guid>?,
            _ ppvObject: UnsafeMutablePointer<UnsafeMutableRawPointer?>?) -> SWRT_HResult {
        guard let this, let iid, let ppvObject else { return COMError.toABI(hresult: HResult.invalidArg) }
        ppvObject.pointee = nil

        return COMError.toABI {
            let id = GUIDBinding.fromABI(iid.pointee)
            let this = IUnknownPointer(OpaquePointer(this))
            let reference = id == uuidof(SWRT_COMEmbedding.self)
                ? IUnknownReference(addingRef: this)
                : try COMEmbedding.getIUnknownUnsafe(this)._queryInterface(id)
            ppvObject.pointee = UnsafeMutableRawPointer(reference.detach())
        }
    }
}
