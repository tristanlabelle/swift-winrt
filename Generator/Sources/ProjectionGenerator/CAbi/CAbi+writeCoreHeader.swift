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

        writer.writeTypedef(type: CType.reference(name: "int32_t"), name: namespacingPrefix + "TrustLevel")

        COMInterfaceDecl(interfaceName: iinspectableName, inspectable: true).write(to: writer)
    }
}