import COM_ABI
import COM_PrivateABI

extension COMEmbedding {
    fileprivate static func getUnmanagedEmbedderUnsafe<ABIStruct>(_ this: UnsafeMutablePointer<ABIStruct>) -> Unmanaged<AnyObject> {
        this.withMemoryRebound(to: SWRT_COMEmbedding.self, capacity: 1) {
            let opaquePointer = UnsafeMutableRawPointer(bitPattern: $0.pointee.swiftEmbedderAndFlags & ~SWRT_COMEmbeddingFlags_Mask)
            assert(opaquePointer != nil, "Bad COM object embedding. The embedder pointer is nil.")
            return Unmanaged<AnyObject>.fromOpaque(opaquePointer!)
        }
    }

    fileprivate static func getIUnknownUnsafe<ABIStruct>(_ this: UnsafeMutablePointer<ABIStruct>) -> IUnknown {
        // IUnknown can either be implemented by the embedder or by a separately stored implementer.
        let opaquePointer = this.withMemoryRebound(to: SWRT_COMEmbedding.self, capacity: 1) {
            if ($0.pointee.swiftEmbedderAndFlags & SWRT_COMEmbeddingFlags_ImplementerIsIUnknown) == 0 {
                // Not extended: The embedder implements IUnknown.
                return UnsafeMutableRawPointer(bitPattern: $0.pointee.swiftEmbedderAndFlags & ~SWRT_COMEmbeddingFlags_Mask)
            } else {
                // Extended: The separately stored implementer implements IUnknown.
                return $0.withMemoryRebound(to: SWRT_COMEmbeddingEx.self, capacity: 1) {
                    $0.pointee.swiftImplementer
                }
            }
        }

        assert(opaquePointer != nil, "Bad COM object embedding. The IUnknown pointer is nil.")
        return Unmanaged<AnyObject>.fromOpaque(opaquePointer!).takeUnretainedValue() as! IUnknown
    }

    /// Gets the Swift object that provides the implementation for the given COM interface,
    /// assuming that it is an embedded COM interface, and otherwise crashes.
    public static func getImplementerUnsafe<ABIStruct, Implementer>(
            _ this: UnsafeMutablePointer<ABIStruct>, type: Implementer.Type = Implementer.self) -> Implementer {
        let opaquePointer = this.withMemoryRebound(to: SWRT_COMEmbedding.self, capacity: 1) {
            if ($0.pointee.swiftEmbedderAndFlags & SWRT_COMEmbeddingFlags_SeparateImplementer) == 0 {
                // Not extended: The embedder is the implementer.
                return UnsafeMutableRawPointer(bitPattern: $0.pointee.swiftEmbedderAndFlags & ~SWRT_COMEmbeddingFlags_Mask)
            } else {
                // Extended: The implementer is stored separately.
                return $0.withMemoryRebound(to: SWRT_COMEmbeddingEx.self, capacity: 1) {
                    $0.pointee.swiftImplementer
                }
            }
        }

        assert(opaquePointer != nil, "Bad COM object embedding. The implementer pointer is nil.")
        return Unmanaged<AnyObject>.fromOpaque(opaquePointer!).takeUnretainedValue() as! Implementer
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

        let unmanaged = COMEmbedding.getUnmanagedEmbedderUnsafe(this)
        _ = unmanaged.retain()
        // Best effort refcount
        return UInt32(_getRetainCount(unmanaged.takeUnretainedValue()))
    }

    public static func Release<ABIStruct>(_ this: UnsafeMutablePointer<ABIStruct>?) -> UInt32 {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return 0
        }

        let unmanaged = COMEmbedding.getUnmanagedEmbedderUnsafe(this)
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
