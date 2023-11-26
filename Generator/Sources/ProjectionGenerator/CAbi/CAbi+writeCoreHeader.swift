import CodeWriters

extension CAbi {
    public static func writeCoreHeader(to output: some TextOutputStream) {
        let writer = CSourceFileWriter(output: output)

        writeBasicTypeIncludes(to: writer)

        // boolean
        writer.writeTypedef(comment: "boolean", type: .reference(name: "uint8_t"), name: boolName)

        // Guid
        writer.writeStruct(comment: "GUID", typedef: true, name: guidName, members: [
            .init(type: .reference(name: "uint32_t"), name: "Data1"),
            .init(type: .reference(name: "uint16_t"), name: "Data2"),
            .init(type: .reference(name: "uint16_t"), name: "Data3"),
            .init(type: .reference(name: "uint8_t"), name: "Data4[8]")
        ])

        // HRESULT
        writer.writeTypedef(comment: "HRESULT", type: .reference(name: "int32_t"), name: hresultName)

        // IUnknown
        COMInterfaceDecl(interfaceName: iunknownName, inspectable: false).write(comment: "IUnknown", to: writer)

        // HSTRING
        writer.writeStruct(comment: "HSTRING", name: hstringName + "_", members: [])
        writer.writeTypedef(type: .reference(kind: .struct, name: hstringName + "_").makePointer(), name: hstringName)

        // TrustLevel (we don't need the enumerants)
        writer.writeTypedef(comment: "TrustLevel", type: CType.reference(name: "int32_t"), name: namespacingPrefix + "TrustLevel")

        // IInspectable
        COMInterfaceDecl(interfaceName: iinspectableName, inspectable: true).write(comment: "IInspectable", to: writer)

        // EventRegistrationToken
        writer.writeStruct(comment: "EventRegistrationToken", typedef: true, name: eventRegistrationTokenName, members: [
            .init(type: .reference(name: "int64_t"), name: "value")
        ])

        // IActivationFactory
        var iactivationFactory = COMInterfaceDecl(interfaceName: iactivationFactoryName, inspectable: true)
        iactivationFactory.addFunction(name: "ActivateInstance", params: [
            .init(type: .reference(name: iinspectableName).makePointer().makePointer(), name: "instance")
        ])
        iactivationFactory.write(comment: "IActivationFactory", to: writer)
    }
}