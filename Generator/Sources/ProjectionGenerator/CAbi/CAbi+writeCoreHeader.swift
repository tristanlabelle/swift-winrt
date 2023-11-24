import CodeWriters

extension CAbi {
    public static func writeCoreHeader(to output: some TextOutputStream) {
        let writer = CSourceFileWriter(output: output)

        writeBasicTypeIncludes(to: writer)

        // Guid
        writer.writeStruct(comment: "GUID", typedef: true, name: guidName, members: [
            .init(type: .reference(name: "uint32_t"), name: "data1"),
            .init(type: .reference(name: "uint16_t"), name: "data2"),
            .init(type: .reference(name: "uint16_t"), name: "data3"),
            .init(type: .reference(name: "uint8_t"), name: "data4[8]")
        ])

        // HSTRING
        writer.writeStruct(comment: "HSTRING", name: hstringName + "_", members: [])
        writer.writeTypedef(type: .reference(kind: .struct, name: hstringName + "_").makePointer(), name: hstringName)

        // HRESULT
        writer.writeTypedef(comment: "HRESULT", type: .reference(name: "int32_t"), name: hresultName)

        // IUnknown
        COMInterfaceDecl(interfaceName: iunknownName, inspectable: false).write(comment: "IUnknown", to: writer)

        // TrustLevel & IInspectable
        writer.writeTypedef(comment: "TrustLevel", type: CType.reference(name: "int32_t"), name: namespacingPrefix + "TrustLevel")

        COMInterfaceDecl(interfaceName: iinspectableName, inspectable: true).write(comment: "IInspectable", to: writer)

        // IActivationFactory
        var iactivationFactory = COMInterfaceDecl(interfaceName: iactivationFactoryName, inspectable: true)
        iactivationFactory.addFunction(name: "ActivateInstance", params: [
            .init(type: .reference(name: iinspectableName).makePointer().makePointer(), name: "instance")
        ])
        iactivationFactory.write(comment: "IActivationFactory", to: writer)
    }
}