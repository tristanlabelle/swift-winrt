import Collections
import DotNetMetadata
import ProjectionGenerator
import FoundationXML
import struct Foundation.URL

internal func writeExeManifestFile(projectionConfig: ProjectionConfig, projection: SwiftProjection, toPath path: String) throws {
    var activatableClassesPerFileName: OrderedDictionary<String, [String]> = [:]
    for module in projection.modulesByName.values {
        guard let moduleConfig = projectionConfig.modules[module.name],
            let fileNameInManifest = moduleConfig.fileNameInManifest else { continue }

        for typeDefinitions in module.typeDefinitionsByNamespace.values {
            for typeDefinition in typeDefinitions {
                guard typeDefinition is ClassDefinition else { continue }
                activatableClassesPerFileName[fileNameInManifest, default: []].append(typeDefinition.fullName)
            }
        }
    }

    let manifest = XMLDocument(rootElement: XMLElement(
        name: "assembly",
        attributes: [
            ("manifestVersion", "1.0"),
            ("xmlns", "urn:schemas-microsoft-com:asm.v1"),
            ("xmlns:winrt", "urn:schemas-microsoft-com:winrt.v1")
        ],
        children: activatableClassesPerFileName.map { fileName, activatableClassNames in
            XMLElement(
                name: "file",
                attributes: [
                    ("name", fileName),
                ],
                children: activatableClassNames.sorted().map { activatableClassName in
                    XMLElement(name: "winrt:activatableClass", attributes: [
                        ("name", activatableClassName),
                        ("threadingModel", "both")
                    ])
                })
        })
    )

    try manifest.xmlData(options: [
        .nodeCompactEmptyElement,
        .nodePrettyPrint
    ]).write(to: URL(fileURLWithPath: path))
}

extension XMLElement {
    fileprivate convenience init(name: String, attributes: [(name: String, value: String)] = [], children: [XMLElement] = []) {
        self.init(name: name)
        for (name, value) in attributes {
            addAttribute(XMLNode.attribute(withName: name, stringValue: value) as! XMLNode)
        }
        for child in children {
            addChild(child)
        }
    }
}