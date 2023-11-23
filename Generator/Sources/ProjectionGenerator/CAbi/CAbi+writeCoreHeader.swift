import CodeWriters

extension CAbi {
    public static func writeCoreHeader(to output: some TextOutputStream) {
        let writer = CSourceFileWriter(output: output)

        writeBasicTypeIncludes(to: writer)

        writer.writeStruct(typedef: true, name: guidName, members: [
            .init(type: .reference(name: "uint32_t"), name: "data1"),
            .init(type: .reference(name: "uint16_t"), name: "data2"),
            .init(type: .reference(name: "uint16_t"), name: "data3"),
            .init(type: .reference(name: "uint8_t"), name: "data4[8]")
        ])

        writer.writeStruct(name: hstringName + "_", members: [])
        writer.writeTypedef(type: .reference(name: hstringName + "_").makePointer(), name: hstringName)

        writer.writeTypedef(type: .reference(name: "int32_t"), name: hresultName)

        COMInterfaceDecl(interfaceName: iunknownName, inspectable: false).write(to: writer)

        writer.writeEnum(typedef: true, name: namespacingPrefix + "TrustLevel", enumerants: [
            .init(name: namespacingPrefix + "TrustLevel_BaseTrust", value: 0),
            .init(name: namespacingPrefix + "TrustLevel_PartialTrust", value: 1),
            .init(name: namespacingPrefix + "TrustLevel_FullTrust", value: 2)
        ])

        COMInterfaceDecl(interfaceName: iinspectableName, inspectable: true).write(to: writer)
    }
}