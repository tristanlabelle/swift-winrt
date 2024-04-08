import CodeWriters
import DotNetMetadata
import ProjectionModel

internal func writeExtensionProperties(
        typeDefinition: TypeDefinition, interfaces: [InterfaceDefinition], static: Bool,
        projection: SwiftProjection, to writer: SwiftSourceFileWriter) throws {
    // Only write the extension if we have at least one property (which needs a getter)
    let hasGetters = try interfaces.contains { try $0.properties.contains { try $0.getter != nil } }
    guard hasGetters else { return }

    let typeName: String
    if let interface = typeDefinition as? InterfaceDefinition {
        typeName = try projection.toProtocolName(interface)
    } else {
        typeName = try projection.toTypeName(typeDefinition)
    }

    try writer.writeExtension(type: .identifier(typeName)) { writer in
        for interface in interfaces {
            for property in interface.properties {
                try writeNonthrowingPropertyImplementation(
                    property: property, static: `static`,
                    projection: projection, to: writer)
            }
        }
    }
}

internal func writeNonthrowingPropertyImplementation(
        property: Property, static: Bool,
        projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    guard let getter = try property.getter else { return }

    let selfKeyword = `static` ? "Self" : "self"

    let writeSetter: ((inout SwiftStatementWriter) throws -> Void)?
    if let setter = try property.setter {
        writeSetter = { writer in
            writer.writeStatement("try! \(selfKeyword).\(SwiftProjection.toMemberName(setter))(newValue)")
        }
    } else {
        writeSetter = nil
    }

    // Convert nullability representation from NullResult errors to implicitly unwrapped optionals (T!)
    var propertyType = try projection.toReturnType(property.type)
    let catchNullResult = projection.isNullAsErrorEligible(try property.type)
    if catchNullResult {
        propertyType = .optional(wrapped: propertyType, implicitUnwrap: true)
    }

    try writer.writeComputedProperty(
        documentation: projection.getDocumentationComment(property),
        visibility: .public,
        static: `static`,
        name: SwiftProjection.toMemberName(property),
        type: propertyType,
        get: { writer in
            let output = writer.output
            output.write("try! ")
            if catchNullResult { output.write("NullResult.catch(") }
            output.write("\(selfKeyword).\(SwiftProjection.toMemberName(getter))()")
            if catchNullResult { output.write(")") }
        },
        set: writeSetter)
}