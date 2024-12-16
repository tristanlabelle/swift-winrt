import COM
import TestsABI
import XCTest

extension COMExportTests {
    func testSecondaryInterfaceImplementerIsClosure() throws {
        var callCount = 0
        do {
            let comTestReference = try ICOMTestClosureBinding.toCOM { callCount += 1 }
            XCTAssertEqual(callCount, 0)
            try comTestReference.interop.comTest()
        }
        XCTAssertEqual(callCount, 1)
    }

    fileprivate enum ICOMTestClosureBinding: COMTwoWayBinding {
        public typealias SwiftObject = () throws -> Void
        public typealias ABIStruct = SWRT_ICOMTest

        public static var interfaceID: COMInterfaceID { uuidof(ABIStruct.self) }
        public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

        public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
            Import(_wrapping: reference).invoke
        }

        public static func toCOM(_ object: @escaping SwiftObject) throws -> ABIReference {
            ICOMTestClosureDelegate(object).toCOM()
        }

        private final class Import: COMImport<ICOMTestBinding> {
            public func invoke() throws { try _interop.comTest() }
        }

        private static var virtualTable: SWRT_ICOMTest_VirtualTable = .init(
            QueryInterface: { IUnknownVirtualTable.QueryInterface($0, $1, $2) },
            AddRef: { IUnknownVirtualTable.AddRef($0) },
            Release: { IUnknownVirtualTable.Release($0) },
            COMTest: { this in _implement(this) { try $0() } })
    }


    fileprivate final class ICOMTestClosureDelegate: COMEmbedderEx, IUnknownProtocol {
        private let closure: @escaping () throws -> Void
        var comEmbedding: COMEmbedding
        override var implementer: AnyObject { closure as AnyObject }

        init(_ closure: @escaping () throws -> Void) {
            self.comEmbedding = .init(virtualTable: ICOMTestClosureBinding.virtualTablePointer, embedder: nil)
            self.closure = closure as AnyObject
            super.init()
            self.comEmbedding.initEmbedder(self as COMEmbedderEx)
        }

        func toCOM() -> COMReference<SWRT_ICOMTest> {
            comEmbedding.toCOM().cast()
        }

        func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
            switch id {
            case IUnknownBinding.interfaceID, ICOMTestClosureBinding.interfaceID:
                return comEmbedding.toCOM().cast()
            default:
                throw COMError.noInterface
            }
        }
    }
}